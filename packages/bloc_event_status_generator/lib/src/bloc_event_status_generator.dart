import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Code generator that creates `Emitter<State>` extensions for Bloc classes
/// annotated with `@blocEventStatus`.
class BlocEventStatusGenerator extends GeneratorForAnnotation<BlocEventStatus> {
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

    // Bloc<TEvent, TState> always has exactly 2 type arguments.
    final typeArgs = blocType.typeArguments;
    final eventType = typeArgs[0];
    final stateType = typeArgs[1];

    // State type always resolves to an InterfaceElement.
    final stateElement = stateType.element! as InterfaceElement;

    final statusType = _findEventStatusesMixinStatusType(stateElement);
    if (statusType == null) {
      throw InvalidGenerationSourceError(
        'State class must use EventStatusesMixin<TEvent, TStatus>.',
        element: element,
      );
    }

    // Status type always resolves to an InterfaceElement.
    final statusElement = statusType.element! as InterfaceElement;

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
      ..writeln('// dart format off')
      ..writeln()
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

    buffer
      ..writeln('}')
      ..writeln()
      ..write('// dart format on');

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
        if (bound != null) {
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
    final methodParams = StringBuffer()..write('T event, $stateTypeName state');

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
          optionalPositionalParams.add(
            '$paramType $paramName = ${param.defaultValueCode}',
          );
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

  /// Derives the method name from a subtype name by stripping both the shared
  /// prefix and the remaining base suffix, then converting to lowerCamelCase.
  ///
  /// Examples:
  /// - `LoadingEventStatus` / `EventStatus`       → `loading`
  /// - `CustomSuccessEventStatus` / `CustomEventStatus` → `success`
  String _deriveMethodName(String subtypeName, String baseName) {
    if (subtypeName == baseName) return _lowerCamelCase(subtypeName);

    // Find the length of the common prefix.
    final minLen = subtypeName.length < baseName.length
        ? subtypeName.length
        : baseName.length;
    var prefixLen = 0;
    while (
        prefixLen < minLen && subtypeName[prefixLen] == baseName[prefixLen]) {
      prefixLen++;
    }

    // The part of baseName after the common prefix (the "base suffix").
    final baseSuffix = baseName.substring(prefixLen);
    // The part of subtypeName after the common prefix.
    final subtypeMiddle = subtypeName.substring(prefixLen);

    String stripped;
    if (subtypeMiddle.endsWith(baseSuffix)) {
      stripped = baseSuffix.isEmpty
          ? subtypeMiddle
          : subtypeMiddle.substring(
              0,
              subtypeMiddle.length - baseSuffix.length,
            );
    } else {
      // Prefix-based stripping didn't match. Fall back to stripping the
      // common *suffix* between subtype and base names. This covers the case
      // where both names share only a trailing part (e.g.
      // LoadingEventStatus / CounterEventStatus → Loading).
      final subLen = subtypeName.length;
      final baseLen = baseName.length;
      final minSufLen =
          subLen < baseLen ? subLen : baseLen;
      var suffixLen = 0;
      while (suffixLen < minSufLen &&
          subtypeName[subLen - 1 - suffixLen] ==
              baseName[baseLen - 1 - suffixLen]) {
        suffixLen++;
      }

      if (suffixLen > 0) {
        stripped = subtypeName.substring(0, subLen - suffixLen);
      } else {
        stripped = subtypeName;
      }
    }

    if (stripped.isEmpty) return _lowerCamelCase(subtypeName);

    return _lowerCamelCase(stripped);
  }

  String _lowerCamelCase(String name) {
    if (name.isEmpty) return name;
    return name[0].toLowerCase() + name.substring(1);
  }
}
