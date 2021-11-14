import 'dart:core';

import 'package:collection/collection.dart';
import 'package:fhir/r4.dart';
import 'package:flutter/foundation.dart';

import '../../../fhir_types/fhir_types.dart';
import '../../questionnaires.dart';

/// Models an individual item of a questionnaire.
///
/// Represents the [QuestionnaireItem] of the FHIR domain model.
///
/// Provides properties of the item.
///
/// Provides access to adjacent items (parent, siblings, children).
class QuestionnaireItemModel with Diagnosticable {
  /// The FHIR [QuestionnaireItem]
  final QuestionnaireItem questionnaireItem;
  final String linkId;
  final QuestionnaireItemModel? parent;
  final QuestionnaireModel questionnaireModel;
  final int level;

  /// Returns whether the item has an initial value.
  ///
  /// True if either initial.value[x] or initialExpression are present.
  bool get hasInitialValue {
    return (questionnaireItem.initial != null &&
            questionnaireItem.initial!.isNotEmpty) ||
        hasInitialExpression;
  }

  bool get hasInitialExpression {
    return questionnaireItem.extension_
            ?.extensionOrNull(
              'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
            )
            ?.valueExpression
            ?.expression !=
        null;
  }

  /// Returns whether the item is enabled/disabled through an enabledWhen condition.
  bool get isEnabledWhen {
    return questionnaireItem.enableWhen?.isNotEmpty ?? false;
  }

  /// Returns whether the item is enabled/disabled through an enabledWhenExpression condition.
  bool get isEnabledWhenExpression {
    return questionnaireItem.extension_?.extensionOrNull(
          'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression',
        ) !=
        null;
  }

  /// Iterate over all enableWhen conditions and do something with them.
  void forEnableWhens(void Function(QuestionnaireEnableWhen qew) f) {
    final enableWhens = questionnaireItem.enableWhen;
    if ((enableWhens != null) && enableWhens.isNotEmpty) {
      for (final enableWhen in enableWhens) {
        f.call(enableWhen);
      }
    }
  }

  /// All children below the current level as FHIR [QuestionnaireItem].
  /// Returns an empty list when there are no children.
  List<QuestionnaireItem> get childQuestionnaireItems {
    return ((questionnaireItem.item == null) ||
            (questionnaireItem.item!.isEmpty))
        ? <QuestionnaireItem>[]
        : questionnaireItem.item!;
  }

  List<QuestionnaireItemModel> get children {
    return questionnaireModel.buildModelsFromItems(
      childQuestionnaireItems,
      this,
      level + 1,
    );
  }

  bool get hasParent => parent != null;

  bool get hasChildren =>
      (questionnaireItem.item != null) && (questionnaireItem.item!.isNotEmpty);

  /// Returns whether the item allows repetition.
  ///
  /// This will not return `true` for repeating `choice` or `open-choice` items,
  /// as these are multiple choice, rather than truly repeating.
  bool get isRepeating =>
      questionnaireItem.repeats == Boolean(true) && !isCodingType;

  bool get isRequired => questionnaireItem.required_ == Boolean(true);

  bool get hasConstraint => constraintExpression != null;

  String? get constraintExpression {
    return questionnaireItem.extension_
        ?.firstWhereOrNull(
          (ext) =>
              ext.url?.value.toString() ==
              'http://hl7.org/fhir/StructureDefinition/questionnaire-constraint',
        )
        ?.extension_
        ?.firstWhereOrNull((ext) => ext.url?.value.toString() == 'expression')
        ?.valueString;
  }

  String? get constraintHuman {
    return questionnaireItem.extension_
        ?.firstWhereOrNull(
          (ext) =>
              ext.url?.value.toString() ==
              'http://hl7.org/fhir/StructureDefinition/questionnaire-constraint',
        )
        ?.extension_
        ?.firstWhereOrNull((ext) => ext.url?.value.toString() == 'human')
        ?.valueString;
  }

  /// Is this item's value calculated?
  bool get isCalculated {
    return isCalculatedExpression || isTotalScore;
  }

  /// Is this item a total score calculation?
  bool get isTotalScore {
    // Checking for read-only is relevant,
    // as there are also input fields (e.g. pain score) with unit {score}.
    return (questionnaireItem.type == QuestionnaireItemType.quantity ||
            questionnaireItem.type == QuestionnaireItemType.decimal) &&
        ((questionnaireItem.readOnly == Boolean(true) &&
                questionnaireItem.unit?.display == '{score}') ||
            questionnaireItem.extension_
                    ?.firstWhereOrNull(
                      (ext) =>
                          ext.url?.value.toString() ==
                          calculatedExpressionExtensionUrl,
                    )
                    ?.valueExpression
                    ?.name
                    .toString() ==
                'score');
  }

  static const String calculatedExpressionExtensionUrl =
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression';

  String? get calculatedExpression {
    return questionnaireItem.extension_
        ?.firstWhereOrNull(
          (ext) =>
              ext.url?.value.toString() == calculatedExpressionExtensionUrl,
        )
        ?.valueExpression
        ?.expression;
  }

  /// Is the value of this item calculated by an expression?
  bool get isCalculatedExpression {
    if (questionnaireItem.extension_?.firstWhereOrNull((ext) {
          return {
            calculatedExpressionExtensionUrl,
            'http://hl7.org/fhir/StructureDefinition/cqf-expression',
          }.contains(ext.url?.value.toString());
        }) !=
        null) {
      return true;
    }

    return false;
  }

  /// Is this itemModel unable to hold a value?
  bool get isStatic => isGroup || isDisplay;

  bool get isGroup => questionnaireItem.type == QuestionnaireItemType.group;

  bool get isDisplay => questionnaireItem.type == QuestionnaireItemType.display;

  bool get isQuestion => !isDisplay && !isGroup;

  bool get isCodingType {
    return questionnaireItem.type == QuestionnaireItemType.choice ||
        questionnaireItem.type == QuestionnaireItemType.open_choice;
  }

  /// Is this item not changeable by end-users?
  ///
  /// Read-only items might still hold a value, such as a calculated value.
  /// This does not consider the completion status of the questionnaire.
  bool get isReadOnly {
    return isStatic ||
        questionnaireItem.readOnly == Boolean(true) ||
        isHidden ||
        isCalculated;
  }

  /// Is this item hidden?
  bool get isHidden {
    return (questionnaireItem.extension_
                ?.extensionOrNull(
                  'http://hl7.org/fhir/StructureDefinition/questionnaire-hidden',
                )
                ?.valueBoolean
                ?.value ==
            true) ||
        isHelp;
  }

  /// The [QuestionnaireItemModel] which contains help text about the current item.
  ///
  /// null, if this doesn't exist.
  QuestionnaireItemModel? get helpItem =>
      children.firstWhereOrNull((itemModel) => itemModel.isHelp);

  bool get isHelp {
    return questionnaireItem.isItemControl('help') ||
        (questionnaireItem.extension_
                ?.extensionOrNull(
                  'http://hl7.org/fhir/StructureDefinition/questionnaire-displayCategory',
                )
                ?.valueCodeableConcept
                ?.coding
                ?.firstOrNull
                ?.code
                ?.value ==
            'help');
  }

  String? get titleText {
    final title = Xhtml.toXhtml(
      questionnaireItem.text,
      questionnaireItem.textElement?.extension_,
    );

    final prefix = Xhtml.toXhtml(
      questionnaireItem.prefix,
      questionnaireItem.prefixElement?.extension_,
    );

    return (prefix != null) ? '$prefix $title' : title;
  }

  /// Returns the `shortText` provided for the item, or null.
  String? get shortText {
    return questionnaireItem.extension_
        ?.extensionOrNull(
          'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-shortText',
        )
        ?.valueString;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(StringProperty('linkId', linkId));
    properties
        .add(FlagProperty('children', value: hasChildren, ifTrue: 'children'));
    properties.add(IntProperty('level', level));
  }

  QuestionnaireItemModel(
    this.questionnaireModel,
    this.questionnaireItem,
    this.linkId,
    this.parent,
    this.level,
  );
}
