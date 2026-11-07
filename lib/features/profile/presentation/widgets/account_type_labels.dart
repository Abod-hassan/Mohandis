import 'package:flutter/material.dart';

import 'package:mohandis/l10n/l10n.dart';

import '../../domain/entities/profile.dart';

/// What each account type is called on screen, and what it changes about a
/// form.
///
/// Here rather than in each screen because the sign-up form, the profile step
/// and the edit form all ask the same three questions of the same enum — and
/// when they each answered for themselves, a type added to one was missing
/// from the others.
extension AccountTypeLabel on AccountType {
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AccountType.individual => l10n.authAccountEngineer,
      AccountType.company => l10n.authAccountCompany,
      AccountType.contractor => l10n.authAccountContractor,
      AccountType.craftsman => l10n.authAccountCraftsman,
      AccountType.equipmentOwner => l10n.authAccountEquipmentOwner,
    };
  }

  /// The mark that stands for this kind in the picker.
  ///
  /// Five short Arabic words are hard to tell apart at a glance while
  /// scrolling, and مقاول and حرفي in particular read alike to somebody
  /// signing up in a hurry. Deliberately five different shapes — a person, a
  /// building, a site, tools, a machine — rather than five variations on a
  /// hammer.
  IconData get icon => switch (this) {
        AccountType.individual => Icons.engineering_rounded,
        AccountType.company => Icons.apartment_rounded,
        AccountType.contractor => Icons.home_work_rounded,
        AccountType.craftsman => Icons.handyman_rounded,
        AccountType.equipmentOwner => Icons.agriculture_rounded,
      };

  /// The line under the name in the picker — what this kind of account can
  /// actually DO, since that is the difference that matters and the one a
  /// person cannot guess from the word alone.
  String summary(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AccountType.individual => l10n.authAccountEngineerHint,
      AccountType.company => l10n.authAccountCompanyHint,
      AccountType.contractor => l10n.authAccountContractorHint,
      AccountType.craftsman => l10n.authAccountCraftsmanHint,
      AccountType.equipmentOwner => l10n.authAccountEquipmentOwnerHint,
    };
  }

  /// What the "name" field is asking for.
  ///
  /// A person types their own name; a company types the company's. The three
  /// in between are a business run under a name that is not necessarily a
  /// person's, so they get the neutral wording rather than either.
  String nameLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AccountType.individual => l10n.authFullName,
      AccountType.company => l10n.authCompanyName,
      _ => l10n.authBusinessName,
    };
  }

  String nameHint(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      AccountType.individual => l10n.authFullNameHint,
      AccountType.company => l10n.authCompanyNameHint,
      _ => l10n.authBusinessNameHint,
    };
  }

  /// What this type's specialty list is called — الاختصاص for an engineer, the
  /// trade for a craftsman, the machine for its owner. Null for the kinds that
  /// have no list to pick from.
  ///
  /// Which kinds those are is [AccountType.hasDisciplineList]'s answer, not a
  /// second list written out here: the screens ask this method whether to show
  /// the field at all, so the two disagreeing would mean a field with no list
  /// behind it.
  String? disciplineLabel(BuildContext context) {
    if (!hasDisciplineList) return null;

    final l10n = context.l10n;
    return switch (this) {
      AccountType.craftsman => l10n.profileTradeLabel,
      AccountType.equipmentOwner => l10n.profileEquipmentLabel,
      _ => l10n.editProfileDiscipline,
    };
  }
}
