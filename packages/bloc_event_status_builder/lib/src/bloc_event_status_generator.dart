import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Code generator that creates `Emitter<State>` extensions for Bloc classes
/// annotated with `@blocEventStatus`.
class BlocEventStatusGenerator
    extends GeneratorForAnnotation<BlocEventStatus> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@blocEventStatus can only be applied to classes.',
        element: element,
      );
    }

    final blocType = _findBlocSupertype(element);
    if (blocType == null) {
      throw InvalidGenerationSourceError(
        '@blocEventStatus can only be applied to classes that extend Bloc.',
        element: element,
      );
    }

    final typeArgs = blocType.typeArguments;
    if (typeArgs.length != 2) {
      throw InvalidGenerationSourceError(
        'Could not resolve Bloc type arguments.',
        element: element,
      );
    }

    final eventType = typeArgs[0];
    final stateType = typeArgs[1];

    final stateElement = stateType.element;
    if (stateElement is! InterfaceElement) {
      throw InvalidGenerationSourceError(
        'State type must be a class.',
        element: element,
      );
    }

    final statusType = _findEventStatusesMixinStatusType(stateElement);
    if (statusType == null) {
      throw InvalidGenerationSourceError(
        'State class must use EventStatusesMixin<TEvent, TStatus>.',
        element: element,
      );
    }

    final statusElement = statusType.element;
    if (statusElement is! InterfaceElement) {
      throw InvalidGenerationSourceError(
        'Status type must be a class or sealed class.',
        element: element,
      );
    }

    final subtypes = _findConcreteSubtypes(statusElement);
    if (subtypes.isEmpty) {
      throw InvalidGenerationSourceError(
        'No concrete subtypes found for ${statusElement.name}. '
        'Ensure your status type is a sealed class or abstract class with '
        'concrete subclasses defined in the same library.',
        element: element,
      );
    }

    return _generateExtension(
      blocName: element.name!,
      eventType: eventType,
      stateType: stateType,
      statusElement: statusElement,
      subtypes: subtypes,
    );
  }

  /// Finds the `Bloc<TEvent, TState>` supertype on the annotated class.
  InterfaceType? _findBlocSupertype(InterfaceElement element) {
    for (final supertype in element.allSupertypes) {
      if (supertype.element.name == 'Bloc') {
        return supertype;
      }
    }
    return null;
  }

  /// Finds the `TStatus` type argument from `EventStatusesMixin<TEvent,
  /// TStatus>` on the state class.
  DartType? _findEventStatusesMixinStatusType(InterfaceElement stateElement) {
    for (final supertype in stateElement.allSupertypes) {
      if (supertype.element.name == 'EventStatusesMixin') {
        final typeArgs = supertype.typeArguments;
        if (typeArgs.length == 2) {
          return typeArgs[1]; // TStatus
        }
      }
    }
    return null;
  }

  /// Finds all concrete (non-abstract) subclasses of [statusElement] in the
  /// same library.
  List<ClassElement> _findConcreteSubtypes(InterfaceElement statusElement) {
    final library = statusElement.library;
    final subtypes = <ClassElement>[];

    for (final cls in library.classes) {
      if (cls == statusElement) continue;
      if (cls.isAbstract) continue;

      // Check if this class extends the status type
      for (final supertype in cls.allSupertypes) {
        if (supertype.element == statusElement) {
          subtypes.add(cls);
          break;
        }
      }
    }

    return subtypes;
  }

  /// Generates the full extension code.
  String _generateExtension({
    required String blocName,
    required DartType eventType,
    required DartType stateType,
    required InterfaceElement statusElement,
    required List<ClassElement> subtypes,
  }) {
    final eventTypeName = eventType.getDisplayString();
    final stateTypeName = stateType.getDisplayString();
    final statusTypeName = statusElement.name!;

    final buffer = StringBuffer()
      ..writeln(
        'extension \$${blocName}EmitterX on Emitter<$stateTypeName> {',
      )
      ..writeln(
        '  void _emitEventStatus<T extends $eventTypeName>(',
      )
      ..writeln('    T event,')
      ..writeln('    $statusTypeName status,')
      ..writeln('    $stateTypeName state,')
      ..writeln('  ) {')
      ..writeln('    this(')
      ..writeln('      state.copyWith(')
      ..writeln(
        '        eventStatuses: state.eventStatuses.update(event, status),',
      )
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }');

    // Generate a method for each concrete subtype
    for (final subtype in subtypes) {
      buffer.writeln();
      _generateMethod(
        buffer: buffer,
        subtype: subtype,
        statusBaseName: statusTypeName,
        eventTypeName: eventTypeName,
        stateTypeName: stateTypeName,
      );
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a convenience method for a single status subtype.
  void _generateMethod({
    required StringBuffer buffer,
    required ClassElement subtype,
    required String statusBaseName,
    required String eventTypeName,
    required String stateTypeName,
  }) {
    final subtypeName = subtype.name!;
    final methodName = _deriveMethodName(subtypeName, statusBaseName);

    final constructor = subtype.unnamedConstructor;
    final params = constructor?.formalParameters ?? [];

    // Collect class type parameters (e.g. TData from SuccessEventStatus<TData>)
    final classTypeParams = subtype.typeParameters;
    final typeParamDecl = StringBuffer();
    final typeArgUsage = StringBuffer();
    if (classTypeParams.isNotEmpty) {
      final decls = classTypeParams.map((tp) {
        final bound = tp.bound;
        if (bound != null &&
            !bound.isDartCoreObject &&
            bound is! DynamicType) {
          return '${tp.name} extends ${bound.getDisplayString()}';
        }
        return tp.name;
      });
      typeParamDecl.write('${decls.join(', ')}, ');
      typeArgUsage.write(
        '<${classTypeParams.map((tp) => tp.name).join(', ')}>',
      );
    }

    // Determine if the constructor can be const
    final canBeConst = constructor != null &&
        constructor.isConst &&
        params.every((p) => p.isOptional);

    // Build method signature
    final methodParams = StringBuffer()
      ..write('T event, $stateTypeName state');

    // Collect optional positional and named params separately
    final optionalPositionalParams = <String>[];
    final namedParams = <String>[];
    final constructorArgs = StringBuffer();

    for (final param in params) {
      final paramType = param.type.getDisplayString();
      final paramName = param.name!;

      if (param.isRequiredNamed) {
        namedParams.add('required $paramType $paramName');
        constructorArgs.write('$paramName: $paramName, ');
      } else if (param.isOptionalNamed) {
        if (param.hasDefaultValue) {
          namedParams.add('$paramType $paramName = ${param.defaultValueCode}');
        } else {
          namedParams.add('$paramType $paramName');
        }
        constructorArgs.write('$paramName: $paramName, ');
      } else if (param.isOptionalPositional) {
        if (param.hasDefaultValue) {
          optionalPositionalParams
              .add('$paramType $paramName = ${param.defaultValueCode}');
        } else {
          optionalPositionalParams.add('$paramType $paramName');
        }
        constructorArgs.write('$paramName, ');
      } else {
        // Required positional
        methodParams.write(', $paramType $paramName');
        constructorArgs.write('$paramName, ');
      }
    }

    // Append optional positional params
    if (optionalPositionalParams.isNotEmpty) {
      methodParams.write(', [${optionalPositionalParams.join(', ')}]');
    }

    // Append named params
    if (namedParams.isNotEmpty) {
      methodParams.write(', {${namedParams.join(', ')}}');
    }

    final constructorArgsStr = constructorArgs.toString();
    final constPrefix =
        canBeConst && constructorArgsStr.isEmpty ? 'const ' : '';

    buffer
      ..writeln(
        '  void $methodName<${typeParamDecl}T extends $eventTypeName>($methodParams) =>',
      )
      ..writeln(
        '      _emitEventStatus(event, '
        '$constPrefix$subtypeName$typeArgUsage($constructorArgsStr), state);',
      );
  }

  /// Derives the method name from a subtype name by stripping the base status
  /// class name suffix and converting to lowerCamelCase.
  ///
  /// E.g. `LoadingEventStatus` with base `EventStatus` → `loading`.
  String _deriveMethodName(String subtypeName, String baseName) {
    String stripped;
    if (subtypeName.endsWith(baseName) && subtypeName != baseName) {
      stripped = subtypeName.substring(
        0,
        subtypeName.length - baseName.length,
      );
    } else {
      stripped = subtypeName;
    }

    if (stripped.isEmpty) return _lowerCamelCase(subtypeName);

    return _lowerCamelCase(stripped);
  }

  String _lowerCamelCase(String name) {
    if (name.isEmpty) return name;
    return name[0].toLowerCase() + name.substring(1);
  }
}
