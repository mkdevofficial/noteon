import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'NoteOn'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Cloud Notes & Tasks'**
  String get appTagline;

  /// No description provided for @navNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navNotes;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue without account'**
  String get continueWithoutAccount;

  /// No description provided for @upgradeAccount.
  ///
  /// In en, this message translates to:
  /// **'Link & Upgrade Account'**
  String get upgradeAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignIn;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get resetEmailSent;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will permanently delete your account and all your notes and tasks. This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeleted;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @searchNotesAndTasks.
  ///
  /// In en, this message translates to:
  /// **'Search notes, tasks, tags...'**
  String get searchNotesAndTasks;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get newNote;

  /// No description provided for @newChecklist.
  ///
  /// In en, this message translates to:
  /// **'New Checklist'**
  String get newChecklist;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @emptyNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get emptyNotesTitle;

  /// No description provided for @emptyNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to capture your thoughts, ideas, or checklists.'**
  String get emptyNotesSubtitle;

  /// No description provided for @emptyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks here'**
  String get emptyTasksTitle;

  /// No description provided for @emptyTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay organized by adding your daily tasks and to-dos.'**
  String get emptyTasksSubtitle;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @trash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trash;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty Trash'**
  String get emptyTrash;

  /// No description provided for @trashPurgeNotice.
  ///
  /// In en, this message translates to:
  /// **'Notes in Trash will be automatically purged after 30 days.'**
  String get trashPurgeNotice;

  /// No description provided for @noteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Note moved to trash'**
  String get noteDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareAsText.
  ///
  /// In en, this message translates to:
  /// **'Share as Text'**
  String get shareAsText;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportPdf;

  /// No description provided for @exportMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get exportMarkdown;

  /// No description provided for @lockNote.
  ///
  /// In en, this message translates to:
  /// **'Lock Note'**
  String get lockNote;

  /// No description provided for @unlockNote.
  ///
  /// In en, this message translates to:
  /// **'Unlock Note'**
  String get unlockNote;

  /// No description provided for @noteLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'This note is locked with biometrics/PIN'**
  String get noteLockedMessage;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @versionHistory.
  ///
  /// In en, this message translates to:
  /// **'Version History'**
  String get versionHistory;

  /// No description provided for @restoreVersion.
  ///
  /// In en, this message translates to:
  /// **'Restore this version'**
  String get restoreVersion;

  /// No description provided for @labels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labels;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Label'**
  String get addLabel;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New Label'**
  String get newLabel;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Label'**
  String get editLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Label'**
  String get deleteLabel;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Label Name'**
  String get labelName;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @templateMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting Notes'**
  String get templateMeeting;

  /// No description provided for @templateJournal.
  ///
  /// In en, this message translates to:
  /// **'Daily Journal'**
  String get templateJournal;

  /// No description provided for @templateShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get templateShopping;

  /// No description provided for @templateProject.
  ///
  /// In en, this message translates to:
  /// **'Project Plan'**
  String get templateProject;

  /// No description provided for @noteTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get noteTitleHint;

  /// No description provided for @noteBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Note content...'**
  String get noteBodyHint;

  /// No description provided for @checklistHint.
  ///
  /// In en, this message translates to:
  /// **'Checklist item...'**
  String get checklistHint;

  /// No description provided for @addChecklistItem.
  ///
  /// In en, this message translates to:
  /// **'+ List item'**
  String get addChecklistItem;

  /// No description provided for @convertItemToTask.
  ///
  /// In en, this message translates to:
  /// **'Convert to Task'**
  String get convertItemToTask;

  /// No description provided for @createTaskFromSelection.
  ///
  /// In en, this message translates to:
  /// **'Create Task from Selection'**
  String get createTaskFromSelection;

  /// No description provided for @linkedTasks.
  ///
  /// In en, this message translates to:
  /// **'Linked Tasks'**
  String get linkedTasks;

  /// No description provided for @linkedNote.
  ///
  /// In en, this message translates to:
  /// **'Linked Note'**
  String get linkedNote;

  /// No description provided for @linkNote.
  ///
  /// In en, this message translates to:
  /// **'Link a Note'**
  String get linkNote;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @smartListToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get smartListToday;

  /// No description provided for @smartListUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get smartListUpcoming;

  /// No description provided for @smartListOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get smartListOverdue;

  /// No description provided for @smartListImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get smartListImportant;

  /// No description provided for @smartListNoDate.
  ///
  /// In en, this message translates to:
  /// **'No Date'**
  String get smartListNoDate;

  /// No description provided for @smartListCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get smartListCompleted;

  /// No description provided for @smartListAll.
  ///
  /// In en, this message translates to:
  /// **'All Tasks'**
  String get smartListAll;

  /// No description provided for @priorityNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get priorityNone;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @statusTodo.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get statusTodo;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @subtasks.
  ///
  /// In en, this message translates to:
  /// **'Subtasks'**
  String get subtasks;

  /// No description provided for @addSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add subtask'**
  String get addSubtask;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get repeatYearly;

  /// No description provided for @repeatCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get repeatCustom;

  /// No description provided for @focusTimer.
  ///
  /// In en, this message translates to:
  /// **'Focus Timer'**
  String get focusTimer;

  /// No description provided for @startTimer.
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get startTimer;

  /// No description provided for @pauseTimer.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTimer;

  /// No description provided for @resetTimer.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTimer;

  /// No description provided for @timeSpent.
  ///
  /// In en, this message translates to:
  /// **'Time spent'**
  String get timeSpent;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewList;

  /// No description provided for @viewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get viewGrid;

  /// No description provided for @viewCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get viewCompact;

  /// No description provided for @viewKanban.
  ///
  /// In en, this message translates to:
  /// **'Kanban'**
  String get viewKanban;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get viewCalendar;

  /// No description provided for @viewAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda'**
  String get viewAgenda;

  /// No description provided for @bulkSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String bulkSelected(Object count);

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get markDone;

  /// No description provided for @postpone.
  ///
  /// In en, this message translates to:
  /// **'Postpone'**
  String get postpone;

  /// No description provided for @postponeDay.
  ///
  /// In en, this message translates to:
  /// **'+1 Day'**
  String get postponeDay;

  /// No description provided for @collaborators.
  ///
  /// In en, this message translates to:
  /// **'Collaborators'**
  String get collaborators;

  /// No description provided for @shareWithUser.
  ///
  /// In en, this message translates to:
  /// **'Share by Email'**
  String get shareWithUser;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @roleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get roleEditor;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @sharedWithMe.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get sharedWithMe;

  /// No description provided for @removeCollaborator.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeCollaborator;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusOffline;

  /// No description provided for @syncStatusError.
  ///
  /// In en, this message translates to:
  /// **'Sync Error'**
  String get syncStatusError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @themeAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Black'**
  String get themeAmoled;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock (Biometrics/PIN)'**
  String get appLock;

  /// No description provided for @appLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Require authentication when opening app'**
  String get appLockDesc;

  /// No description provided for @dailyAgendaNotification.
  ///
  /// In en, this message translates to:
  /// **'Daily Agenda Notification'**
  String get dailyAgendaNotification;

  /// No description provided for @agendaTime.
  ///
  /// In en, this message translates to:
  /// **'Agenda Time'**
  String get agendaTime;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export All Data (JSON)'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data (JSON/Text/MD)'**
  String get importData;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Local Cache'**
  String get clearCache;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Productivity & Stats'**
  String get statistics;

  /// No description provided for @completedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Completed this week'**
  String get completedThisWeek;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue Tasks'**
  String get overdueTasks;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Call Ahmed tomorrow 5pm !high #work'**
  String get quickAddHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @wordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String wordsCount(Object count);

  /// No description provided for @charsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} chars'**
  String charsCount(Object count);

  /// No description provided for @lastEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited {time}'**
  String lastEdited(Object time);

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created {time}'**
  String created(Object time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
