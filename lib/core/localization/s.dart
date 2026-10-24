/// Centralized UI strings.
///
/// The app ships in Arabic (default, RTL) with French as a second language.
/// Every user-visible string lives here so no screen ever hard-codes text.
class S {
  S(this.locale);

  /// `'ar'` or `'fr'`.
  final String locale;

  bool get isAr => locale != 'fr';

  String _t(String ar, String fr) => isAr ? ar : fr;

  // ---------------------------------------------------------------- generic
  String get appName => _t('مصاريفي', 'Masarifi');
  String get save => _t('حفظ', 'Enregistrer');
  String get saveChanges => _t('حفظ التغييرات', 'Enregistrer');
  String get cancel => _t('إلغاء', 'Annuler');
  String get delete => _t('حذف', 'Supprimer');
  String get edit => _t('تعديل', 'Modifier');
  String get add => _t('إضافة', 'Ajouter');
  String get confirm => _t('تأكيد', 'Confirmer');
  String get send => _t('إرسال', 'Envoyer');
  String get close => _t('إغلاق', 'Fermer');
  String get retry => _t('إعادة المحاولة', 'Réessayer');
  String get loading => _t('جارٍ التحميل…', 'Chargement…');
  String get errorGeneric => _t(
    'حدث خطأ غير متوقع. حاول مرة أخرى.',
    'Une erreur inattendue est survenue. Réessayez.',
  );
  String get errorNetwork => _t(
    'تعذّر الاتصال بالشبكة. تحقّق من إنترنتك.',
    'Impossible de se connecter au réseau. Vérifiez votre connexion.',
  );
  String get emptyTitle =>
      _t('لا توجد بيانات بعد', 'Aucune donnée pour le moment');
  String get emptySubtitle =>
      _t('أضف أول عنصر لتظهر هنا.', 'Ajoutez un élément pour l\'afficher ici.');
  String get deleteConfirmTitle =>
      _t('تأكيد الحذف', 'Confirmer la suppression');
  String get deleteConfirmMessage => _t(
    'هل تريد حذف هذا العنصر؟ لا يمكن التراجع.',
    'Voulez-vous supprimer cet élément ? Action irréversible.',
  );
  String get deletedDone => _t('تم الحذف', 'Supprimé');
  String get required => _t('مطلوب', 'Obligatoire');
  String get optional => _t('اختياري', 'Facultatif');
  String get requiredLabel => _t('مطلوب', 'Obligatoire');
  String get unsavedChanges => _t(
    'لديك تغييرات غير محفوظة',
    'Vous avez des modifications non enregistrées',
  );
  String get comingSoon => _t('قريباً', 'Bientôt disponible');

  String fieldRequired(String name) =>
      _t('الحقل "$name" مطلوب', 'Le champ « $name » est obligatoire');
  String get amount => _t('المبلغ', 'Montant');
  String get date => _t('التاريخ', 'Date');
  String get note => _t('ملاحظة', 'Note');
  String get name => _t('الاسم', 'Nom');
  String get email => _t('البريد الإلكتروني', 'E-mail');
  String get password => _t('كلمة المرور', 'Mot de passe');
  String get today => _t('اليوم', "Aujourd'hui");
  String get yesterday => _t('أمس', 'Hier');
  String get none => _t('بدون', 'Aucun');
  String get all => _t('الكل', 'Tous');
  String get of => _t('من', 'sur');

  // ------------------------------------------------------------------ auth
  String get signIn => _t('تسجيل الدخول', 'Connexion');
  String get signUp => _t('إنشاء حساب', 'Créer un compte');
  String get signInTitle => _t('مرحباً بعودتك', 'Bon retour');
  String get signInSubtitle => _t(
    'سجّل دخولك لمتابعة مصاريفك',
    'Connectez-vous pour suivre vos dépenses',
  );
  String get signUpTitle => _t('حساب جديد', 'Nouveau compte');
  String get signUpSubtitle => _t(
    'ابدأ في تنظيم راتبك شهرياً',
    'Commencez à organiser votre salaire mensuel',
  );
  String get displayName => _t('الاسم الكامل', 'Nom complet');
  String get confirmPassword =>
      _t('تأكيد كلمة المرور', 'Confirmer le mot de passe');
  String get signInWithGoogle =>
      _t('المتابعة بحساب Google', 'Continuer avec Google');
  String get forgotPassword =>
      _t('نسيت كلمة المرور ?', 'Mot de passe oublié ?');
  String get passwordResetSent => _t(
    'تم إرسال رابط إعادة التعيين إلى بريدك',
    'Un lien de réinitialisation a été envoyé par e-mail',
  );
  String get noAccount => _t('ليس لديك حساب ؟', 'Pas encore de compte ?');
  String get haveAccount =>
      _t('لديك حساب بالفعل ؟', 'Vous avez déjà un compte ?');
  String get signOut => _t('تسجيل الخروج', 'Déconnexion');
  String get signOutConfirm =>
      _t('هل تريد تسجيل الخروج من حسابك ؟', 'Voulez-vous vous déconnecter ?');
  String get invalidEmail =>
      _t('صيغة البريد الإلكتروني غير صحيحة', 'Format d\'e-mail invalide');
  String get passwordTooShort => _t(
    'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
    'Le mot de passe doit contenir au moins 6 caractères',
  );
  String get passwordsDoNotMatch => _t(
    'كلمتا المرور غير متطابقتين',
    'Les mots de passe ne correspondent pas',
  );
  String get tooLong =>
      _t('القيمة أطول من اللازم', 'La valeur est trop longue');
  String get authInvalidEmail =>
      _t('البريد الإلكتروني غير صالح', 'Adresse e-mail invalide');
  String get authUserDisabled =>
      _t('هذا الحساب معطّل', 'Ce compte est désactivé');
  String get authWrongCredentials =>
      _t('البريد أو كلمة المرور غير صحيحة', 'E-mail ou mot de passe incorrect');
  String get authEmailInUse =>
      _t('هذا البريد مستخدم لحساب آخر', 'Cet e-mail est déjà utilisé');
  String get authWeakPassword =>
      _t('كلمة المرور ضعيفة جداً', 'Mot de passe trop faible');
  String get authNotAllowed => _t(
    'طريقة الدخول غير مفعّلة في المشروع',
    'Méthode de connexion non activée',
  );
  String get authTooManyRequests => _t(
    'محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة',
    'Trop de tentatives. Patientez puis réessayez',
  );
  String get authRequiresRecentLogin => _t(
    'سجّل الدخول من جديد لأسباب أمنية',
    'Reconnectez-vous pour des raisons de sécurité',
  );
  String get authQuotaExceeded => _t(
    'تم تجاوز الحد المسموح. حاول لاحقاً',
    'Quota dépassé. Réessayez plus tard',
  );
  String get authInvalidActionCode =>
      _t('رابط غير صالح أو منتهي', 'Lien invalide ou expiré');
  String get authAccountExists => _t(
    'حساب موجود بنفس البريد بطريقة أخرى',
    'Un compte existe déjà avec cet e-mail',
  );
  String get authTokenExpired => _t(
    'انتهت الجلسة. سجّل الدخول مجدداً',
    'Session expirée. Reconnectez-vous',
  );
  String get authCancelled => _t('تم إلغاء العملية', 'Opération annulée');
  String get checkingSession =>
      _t('جارٍ فتح الجلسة…', 'Ouverture de la session…');

  // ------------------------------------------------------ setup / settings
  String get setupTitle =>
      _t('إعداد فترة الراتب', 'Configurer la période de salaire');
  String get setupSubtitle => _t(
    'حدّد راتبك الشهري ويوم استلامه لنحسب لك المتبقي يوماً بيوم',
    'Définissez votre salaire et sa date de réception pour calculer votre reste au quotidien',
  );
  String get monthlySalary => _t('الراتب الشهري', 'Salaire mensuel');
  String get monthlySalaryHint =>
      _t('الراتب الصافي بالدينار', 'Salaire net en dinars');
  String get payday => _t('يوم استلام الراتب', 'Jour de paie');
  String get paydayHint => _t(
    'رقم من 1 إلى 31 — في الأشهر القصيرة يُحتسب آخر يوم',
    'De 1 à 31 — le dernier jour des mois plus courts',
  );
  String get paydayValue => _t('يوم', 'Jour');
  String get invalidAmount => _t(
    'أدخل مبلغاً صحيحاً (أرقام فقط)',
    'Saisissez un montant valide (chiffres)',
  );
  String get amountTooLarge => _t('المبلغ كبير جداً', 'Montant trop élevé');
  String get invalidPayday =>
      _t('أدخل يوماً بين 1 و 31', 'Saisissez un jour entre 1 et 31');
  String get setupContinue => _t('ابدأ', 'Commencer');
  String get currencyDisplay =>
      _t('طريقة عرض المبالغ', 'Affichage des montants');
  String get currencyDzd => _t('دينار (12,500 دج)', 'Dinars (12 500 دج)');
  String get currencyMillions =>
      _t('الأسلوب الجزائري (1.25 مليون)', 'Style algérien (1,25 مليون)');
  String get currencyDisplayHint => _t(
    'الأسلوب الجزائري يعرض المبالغ بملايين السنتيم',
    'Le style algérien affiche les montants en millions de centimes',
  );
  String get language => _t('اللغة', 'Langue');
  String get arabicLabel => _t('العربية', 'Arabe');
  String get theme => _t('المظهر', 'Apparence');
  String get themeSystem => _t('حسب النظام', 'Système');
  String get themeLight => _t('فاتح', 'Clair');
  String get themeDark => _t('داكن', 'Sombre');
  String get settings => _t('الإعدادات', 'Paramètres');
  String get profile => _t('الملف الشخصي', 'Profil');
  String get account => _t('الحساب', 'Compte');
  String get salaryAndPayday =>
      _t('الراتب ويوم الدفع', 'Salaire et jour de paie');

  // Settings sections and short labels.
  String get mySalary => _t('راتبي', 'Mon salaire');
  String get moneyTools => _t('أدوات المال', 'Outils');
  String get preferences => _t('التفضيلات', 'Préférences');
  String get accountAndData => _t('الحساب والبيانات', 'Compte et données');
  String get languageAndDisplay => _t('اللغة والعرض', 'Langue et affichage');
  String get organizeOperations =>
      _t('تنظيم العمليات', 'Organisation des opérations');
  String get moneyToolsHint => _t(
    'الاشتراكات، الميزانيات، الأهداف، الدَّارات، التقارير',
    'Abonnements, budgets, objectifs, dawras, rapports',
  );
  String get preferencesHint => _t(
    'التذكيرات، اللغة، المظهر، عرض المبالغ، الفئات',
    'Rappels, langue, apparence, montants, catégories',
  );
  String get accountAndDataHint => _t(
    'النسخة الاحتياطية وحذف الحساب',
    'Sauvegarde et suppression du compte',
  );
  String get setUpSalary =>
      _t('حدّد راتبك ويوم استلامه', 'Indiquez votre salaire et jour de paie');
  String paydayOfMonth(int day) =>
      _t('يوم $day من كل شهر', 'le $day de chaque mois');
  String get toolGoals => _t('الأهداف', 'Objectifs');
  String get toolSeasonal => _t('المواسم', 'Saisons');
  String get currencyDzdShort => _t('بالدينار', 'En dinars');
  String get currencyMillionsShort => _t('بالمليون', 'En millions');
  String get remindersOn => _t('مفعّلة', 'Activés');
  String get remindersOff => _t('متوقفة', 'Désactivés');
  String get savedDone => _t('تم الحفظ', 'Enregistré');
  String get setupLater => _t(
    'يمكنك تعديلها لاحقاً من الإعدادات',
    'Vous pourrez la modifier plus tard dans les paramètres',
  );
  String get about => _t('حول التطبيق', 'À propos');
  String get aboutText => _t(
    'مصاريفي — تطبيق لتسيير مصاريف الموظف في الجزائر. المبالغ بالدينار الجزائري.',
    'Masarifi — application de gestion des dépenses pour salariés en Algérie. Montants en dinars algériens.',
  );

  // --------------------------------------------------------------- shell
  String get navDashboard => _t('الرئيسية', 'Accueil');
  String get navAccounts => _t('الحسابات', 'Comptes');
  String get navTransactions => _t('العمليات', 'Opérations');
  String get navSettings => _t('الإعدادات', 'Réglages');
  String get navDebts => _t('الديون', 'Dettes');
  String get categories => _t('الفئات', 'Catégories');

  // ------------------------------------------------------------ dashboard
  String get remaining =>
      _t('المتبقي حتى الراتب القادم', 'Restant jusqu\'au prochain salaire');
  String get daysLeft => _t('يوم متبقٍ', 'jours restants');
  String get dayLeft => _t('يوم واحد', 'un jour restant');
  String get dailyAllowance => _t('المصروف اليومي', 'Dépense quotidienne');
  String get canSpendToday =>
      _t('تستطيع أن تصرف اليوم', 'Vous pouvez dépenser aujourd’hui');
  String get todayBudgetUsed =>
      _t('صرفت كل مصروف اليوم', 'Budget du jour entièrement dépensé');
  String overspentToday(String amount) =>
      _t('تجاوزت مصروف اليوم بـ $amount', 'Budget du jour dépassé de $amount');
  String spentOfToday(String spent, String budget) => _t(
    'صرفت $spent من $budget اليوم',
    '$spent dépensés sur $budget aujourd’hui',
  );
  String daysToPayday(int n) {
    if (!isAr) {
      return n == 1 ? '1 jour avant la paie' : '$n jours avant la paie';
    }
    if (n == 1) return 'يوم واحد للراتب';
    if (n == 2) return 'يومان للراتب';
    if (n >= 3 && n <= 10) return '$n أيام للراتب';
    return '$n يوماً للراتب';
  }

  String get beforePayday => _t('قبل الراتب', 'Avant la paie');
  String get nothingBeforePayday => _t(
    'لا فواتير ولا ديون مستحقة قبل الراتب',
    'Aucune facture ni dette à régler avant la paie',
  );
  String get debtDue => _t('دين', 'Dette');
  String get billDue => _t('فاتورة', 'Facture');
  String get salaryNotRecorded => _t(
    'لم تسجّل راتب هذه الفترة في حساباتك بعد',
    'Le salaire de cette période n’est pas encore enregistré',
  );
  String budgetAlert(String category, String percent) => _t(
    'ميزانية $category: صرفت $percent من السقف',
    'Budget $category : $percent du plafond',
  );
  String oldDebtAlert(String person) => _t(
    '$person مدين لك منذ أكثر من شهرين',
    '$person vous doit depuis plus de deux mois',
  );
  String get periodSummary => _t('ملخص الفترة', 'Résumé de la période');
  String get openReports => _t('كل التقارير', 'Tous les rapports');
  String get negativeWarning => _t(
    'تجاوزت الميزانية! قلّل مصاريفك أو انتظر الراتب.',
    'Budget dépassé ! Réduisez vos dépenses ou attendez le salaire.',
  );
  String get noAllowance => _t(
    'لا يمكن حساب المبلغ اليومي',
    'Impossible de calculer le montant quotidien',
  );
  String get period => _t('الفترة', 'Période');
  String get recordSalary => _t('تسجيل الراتب', 'Enregistrer le salaire');
  String get salaryRecorded =>
      _t('تم تسجيل الراتب في حسابك', 'Salaire enregistré sur votre compte');
  String get salaryAlreadyRecorded => _t(
    'سجلت راتب هذه الفترة مسبقاً',
    'Le salaire de cette période est déjà enregistré',
  );
  String get income => _t('الدخل', 'Revenus');
  String get expenses => _t('المصاريف', 'Dépenses');
  String get extraIncome => _t('دخل إضافي', 'Revenus supplémentaires');
  String get setAsideInGoals =>
      _t('مُدّخر في الأهداف', 'Mis de côté (objectifs)');
  String get dawraNet => _t('صافي الدَّارة', 'Solde dawra');
  String get balance => _t('الرصيد', 'Solde');
  String get thisPeriod => _t('هذه الفترة', 'Cette période');
  String get lastPeriod => _t('الفترة السابقة', 'Période précédente');
  String get spendingByCategory =>
      _t('المصاريف حسب الفئة', 'Dépenses par catégorie');
  String get noSpendingYet =>
      _t('لا توجد مصاريف في هذه الفترة', 'Aucune dépense cette période');
  String get comparison =>
      _t('مقارنة بالفترة السابقة', 'Comparaison avec la période précédente');
  String get expensesUp => _t('زيادة في المصاريف', 'Hausse des dépenses');
  String get expensesDown => _t('انخفاض في المصاريف', 'Baisse des dépenses');
  String get sameAsLast =>
      _t('مطابقة للفترة السابقة', 'Identique à la période précédente');
  String get netDebts => _t('الديون', 'Dettes');
  String get owedToMe => _t('ديون لي', 'On me doit');
  String get iOwe => _t('ديون عليّ', 'Je dois');
  String get noDebtsYet => _t('لا توجد ديون مسجلة', 'Aucune dette enregistrée');
  String get dueBeforePayday =>
      _t('تستحق قبل الراتب', 'Échéance avant la paie');
  String get recent => _t('آخر العمليات', 'Dernières opérations');
  String get seeAll => _t('عرض الكل', 'Voir tout');
  String get savings => _t('الادخار', 'Épargne');
  String get quickAdd => _t('إضافة عملية', 'Nouvelle opération');

  // ------------------------------------------------------------- accounts
  String get accounts => _t('الحسابات والمحافظ', 'Comptes et portefeuilles');
  String get addAccount => _t('إضافة حساب', 'Ajouter un compte');
  String get editAccount => _t('تعديل الحساب', 'Modifier le compte');
  String get accountName => _t('اسم الحساب', 'Nom du compte');
  String get accountType => _t('نوع الحساب', 'Type de compte');
  String get cash => _t('نقد', 'Espèces');
  String get ccp => _t('CCP / باريدي موب', 'CCP / BaridiMob');
  String get bankCard => _t('بطاقة بنكية', 'Carte bancaire');
  String get other => _t('أخرى', 'Autre');
  String get initialBalance => _t('الرصيد الابتدائي', 'Solde initial');
  String get totalBalance => _t('مجموع الأرصدة', 'Total des soldes');
  String get transfer => _t('تحويل بين الحسابات', 'Virement entre comptes');
  String get transferFrom => _t('من حساب', 'De');
  String get transferTo => _t('إلى حساب', 'Vers');
  String get transferAmount => _t('مبلغ التحويل', 'Montant du virement');
  String get insufficientBalance =>
      _t('الرصيد غير كافٍ في هذا الحساب', 'Solde insuffisant sur ce compte');
  String get transferDone => _t('تم التحويل', 'Virement effectué');
  String get deleteAccountConfirm => _t(
    'حذف الحساب ستحوّل معاملاته إلى حساب آخر. متابعة؟',
    'La suppression transférera ses opérations vers un autre compte. Continuer ?',
  );
  String get pickAccount => _t('اختر حساباً', 'Choisissez un compte');
  String get accountInUse => _t(
    'لا يمكن حذف حساب توجد عليه عمليات',
    'Impossible de supprimer un compte avec des opérations',
  );
  String get categoryInUse => _t(
    'لا يمكن حذف فئة مستعملة في عمليات أو ميزانيات أو اشتراكات',
    'Impossible de supprimer une catégorie utilisée par des opérations, budgets ou abonnements',
  );
  String get categorySystemLocked => _t(
    'هذه فئة أساسية يستعملها التطبيق تلقائياً: يمكن تعديلها لكن لا يمكن حذفها',
    'Catégorie système utilisée automatiquement : modifiable mais non supprimable',
  );
  String get noAccounts => _t('لا توجد حسابات', 'Aucun compte');

  // ----------------------------------------------------------- categories
  String get addCategory => _t('إضافة فئة', 'Ajouter une catégorie');
  String get editCategory => _t('تعديل الفئة', 'Modifier la catégorie');
  String get categoryName => _t('اسم الفئة', 'Nom de la catégorie');
  String get icon => _t('الأيقونة', 'Icône');
  String get color => _t('اللون', 'Couleur');
  String get categoryKind => _t('نوع الفئة', 'Type de catégorie');
  String get kindBoth => _t('دخل ومصاريف', 'Revenus et dépenses');
  String get kindExpense => _t('مصاريف فقط', 'Dépenses seulement');
  String get kindIncome => _t('دخل فقط', 'Revenus seulement');
  String get deleteCategoryConfirm => _t(
    'حذف الفئة سيجعل عملياتها بدون تصنيف. متابعة؟',
    'Supprimer la catégorie laissera ses opérations sans classification. Continuer ?',
  );
  String get uncategorized => _t('غير مصنّف', 'Non classé');
  String get noCategories => _t('لا توجد فئات', 'Aucune catégorie');

  // -------------------------------------------------------- transactions
  String get transactions => _t('العمليات', 'Opérations');
  String get addTransaction => _t('عملية جديدة', 'Nouvelle opération');
  String get editTransaction => _t('تعديل العملية', 'Modifier l\'opération');
  String get expense => _t('مصروف', 'Dépense');
  String get incomeShort => _t('دخل', 'Revenu');
  String get transferShort => _t('تحويل', 'Virement');
  String get selectCategory => _t('اختر الفئة', 'Choisissez une catégorie');
  String get selectAccount => _t('اختر الحساب', 'Choisissez un compte');
  String get notePlaceholder => _t('ملاحظة (اختياري)', 'Note (facultatif)');
  String get next => _t('التالي', 'Suivant');
  String get previous => _t('السابق', 'Précédent');
  String get category => _t('الفئة', 'Catégorie');
  String get fastAddHint =>
      _t('أدخل المبلغ ثم اختر الفئة', 'Saisissez le montant puis la catégorie');
  String get deleteTransactionConfirm => _t(
    'حذف العملية سيعيد المبلغ إلى الحساب. متابعة؟',
    'La suppression remboursera le montant sur le compte. Continuer ?',
  );
  String get deleteLinkedTransactionConfirm => _t(
    'هذه العملية مرتبطة بدين أو اشتراك أو دَّارة. حذفها سيعيد المبلغ إلى الحساب ويلغي الدفعة المرتبطة بها. متابعة؟',
    'Cette opération est liée à une dette, un abonnement ou une dawra. La supprimer rembourse le compte et annule le paiement lié. Continuer ?',
  );
  String get linkedTransactionHint => _t(
    'المبلغ والنوع يُداران من الدين أو الاشتراك أو الدَّارة المرتبطة.',
    "Le montant et le type sont gérés par la dette, l'abonnement ou la dawra liée.",
  );
  String get loadMore => _t('عرض عمليات أقدم', 'Afficher plus');
  String get noTransactions => _t('لا توجد عمليات', 'Aucune opération');
  String get noTransactionsPeriod =>
      _t('لا توجد عمليات في هذه الفترة', 'Aucune opération sur cette période');
  String get transactionSaved => _t('تمت إضافة العملية', 'Opération ajoutée');
  String get transactionDeleted => _t('تم حذف العملية', 'Opération supprimée');
  String get type => _t('النوع', 'Type');
  String get sourceManual => _t('يدوي', 'Manuel');
  String get sourceSubscription => _t('اشتراك', 'Abonnement');
  String get sourceDebt => _t('دين', 'Dette');
  String get sourceSalary => _t('راتب', 'Salaire');

  // ---------------------------------------------------------------- debts
  String get debts => _t('الديون', 'Dettes');
  String get reminders => _t('تذكير', 'Rappel');
  String get addDebt => _t('دين جديد', 'Nouvelle dette');
  String get editDebt => _t('تعديل الدين', 'Modifier la dette');
  String get debtType => _t('نوع الدين', 'Type de dette');
  String get person => _t('الشخص', 'Personne');
  String get personHint => _t('اسم الشخص', 'Nom de la personne');
  String get phone => _t('رقم الهاتف', 'Numéro de téléphone');
  String get dueDate => _t('تاريخ الاستحقاق', 'Date d\'échéance');
  String get totalAmount => _t('المبلغ الكلي', 'Montant total');
  String get paidAmount => _t('المسدَّد', 'Déjà payé');
  String get amountRemaining => _t('المتبقي', 'Restant');
  String get recordPayment => _t('تسجيل دفعة', 'Enregistrer un paiement');
  String get payDebt => _t('تسديد', 'Rembourser');
  String get collectDebt => _t('تحصيل', 'Encaisser');
  String get paymentSaved => _t('تم تسجيل الدفعة', 'Paiement enregistré');
  String get debtSaved => _t('تم حفظ الدين', 'Dette enregistrée');
  String get debtDeleted => _t('تم حذف الدين', 'Dette supprimée');
  String get oldDebt => _t('دين قديم', 'Dette ancienne');
  String get addToBalance => _t('أضف المبلغ إلى الريد', 'Créditer le solde');
  String get addToBalanceHint => _t(
    'عند الاقتراض يُضاف المبلغ للرصيد، وعند الإعارة يُخصم',
    'Emprunter crédite le solde, prêter le débite',
  );
  String get paymentsHistory => _t('سجل الدفعات', 'Historique des paiements');
  String get noPaymentsYet =>
      _t('لا توجد دفعات بعد', 'Aucun paiement pour le moment');
  String get paymentAmountHint => _t(
    'المبلغ المسدَّد جزئياً أو كاملاً',
    'Montant payé, partiellement ou entièrement',
  );
  String get paymentsTotalHint => _t(
    'لا يمكن تجاوز المتبقي',
    'Le montant ne peut pas dépasser le restant dû',
  );
  String get debtSettled => _t('مسدَّد بالكامل', 'Entièrement réglée');
  String get unpaid => _t('غير مسدَّد', 'Non réglée');
  String get deleteDebtConfirm => _t(
    'حذف الدين سيحذف سجل دفعاته. متابعة؟',
    'Supprimer la dette effacera aussi son historique. Continuer ?',
  );

  // -------------------------------------------------------- subscriptions
  String get subscriptions => _t('الاشتراكات', 'Abonnements');
  String get addSubscription => _t('اشتراك جديد', 'Nouvel abonnement');
  String get editSubscription => _t('تعديل الاشتراك', 'Modifier l\'abonnement');
  String get subscriptionName => _t('اسم الاشتراك', 'Nom de l\'abonnement');
  String get billingCycle => _t('دورة الدفع', 'Périodicité');
  String get cycleMonthly => _t('شهري', 'Mensuel');
  String get cycleWeekly => _t('أسبوعي', 'Hebdomadaire');
  String get cycleYearly => _t('سنوي', 'Annuel');
  String get nextDueDate => _t('الاستحقاق القادم', 'Prochaine échéance');
  String get markPaid => _t('تم الدفع', 'Marquer payé');
  String get subscriptionPaid =>
      _t('تم تسجيل دفعة الاشتراك', 'Abonnement payé et enregistré');
  String get subscriptionSaved =>
      _t('تم حفظ الاشتراك', 'Abonnement enregistré');
  String get subscriptionDeleted =>
      _t('تم حذف الاشتراك', 'Abonnement supprimé');
  String get activeSubscription => _t('فعّال', 'Actif');
  String get pausedSubscription => _t('موقوف', 'Suspendu');
  String get noSubscriptions => _t('لا توجد اشتراكات', 'Aucun abonnement');
  String get dueToday => _t('يستحق اليوم', 'Échéance aujourd\'hui');
  String get dueTomorrow => _t('يستحق غداً', 'Échéance demain');
  String get overdue => _t('متأخر', 'En retard');
  String get upcomingBills =>
      _t('المستحقات قبل الراتب', 'Échéances avant la paie');
  String get noUpcomingBills =>
      _t('لا توجد مستحقات قبل الراتب', 'Aucune échéance avant la paie');
  String get subscriptionsDueTotal =>
      _t('مجموع الاشتراكات المستحقة', 'Total des abonnements dus');
  String get pauseSubscription => _t('إيقاف مؤقت', 'Suspendre');
  String get resumeSubscription => _t('استئناف', 'Reprendre');
  String get deleteSubscriptionConfirm => _t(
    'حذف هذا الاشتراك؟ لا يمكن التراجع.',
    'Supprimer cet abonnement ? Action irréversible.',
  );

  // -------------------------------------------------------- notifications
  String get notifications => _t('الإشعارات', 'Notifications');
  String get remindersToggle =>
      _t('تذكيرات الاستحقاقات', 'Rappels d\'échéances');
  String get remindersHint => _t(
    'إشعار بيوم واحد قبل الاستحقاقات وقبل يوم الراتب',
    'Rappel un jour avant les échéances et avant le jour de paie',
  );
  String get notificationsDenied => _t(
    'لم يتم منح إذن الإشعارات من النظام',
    'Permission de notification non accordée',
  );
  String get reminderChannelName => _t('التذكيرات', 'Rappels');
  String get reminderChannelDescription => _t(
    'تذكيرات باستحقاقات الاشتراكات والديون ويوم الراتب',
    'Rappels des échéances d’abonnements, de dettes et du jour de paie',
  );
  String get notificationsOn => _t('التذكيرات مفعّلة', 'Rappels activés');
  String get notificationsOff => _t('التذكيرات متوقفة', 'Rappels désactivés');
  String get subscriptionDueToday => _t('يستحق اليوم', 'Expire aujourd\'hui');
  String get subscriptionDueTomorrow => _t('يستحق غداً', 'Expire demain');
  String get debtDueToday => _t('يستحق اليوم', 'Échéance aujourd\'hui');
  String get paydayTomorrow =>
      _t('غداً استلام الراتب', 'Réception du salaire demain');
  String get paydayToday =>
      _t('يوم الراتب — استلم راتبك', 'Jour de paie — récupérez votre salaire');

  // ------------------------------------------------------------- budgets
  String get budgets => _t('الميزانيات', 'Budgets');
  String get addBudget => _t('ميزانية جديدة', 'Nouveau budget');
  String get editBudget => _t('تعديل الميزانية', 'Modifier le budget');
  String get budgetLimit => _t('سقف المصاريف', 'Plafond mensuel');
  String get spent => _t('المصروف', 'Dépensé');
  String get remainingBudget => _t('المتبقي من الميزانية', 'Reste du budget');
  String get ofBudget => _t('من الميزانية', 'du budget');
  String get noBudgetsYet =>
      _t('لا توجد ميزانيات لهذا الشهر', 'Aucun budget ce mois');
  String get budgetWarning =>
      _t('اقتربت من سقف الفئة', 'Proche du plafond de la catégorie');
  String get budgetExceeded =>
      _t('تجاوزت سقف الفئة', 'Plafond de la catégorie dépassé');
  String get budgetSaved => _t('تم حفظ الميزانية', 'Budget enregistré');
  String get budgetDeleted => _t('تم حذف الميزانية', 'Budget supprimé');
  String get setBudgetLimit => _t(
    'حدد سقفاً شهرياً لهذه الفئة',
    'Fixez un plafond mensuel pour cette catégorie',
  );
  String get deleteBudgetConfirm =>
      _t('حذف هذه الميزانية؟', 'Supprimer ce budget ?');
  String get monthlyBudgets => _t('ميزانيات الشهر', 'Budgets du mois');

  // --------------------------------------------------------------- goals
  String get goals => _t('أهداف الادخار', 'Objectifs d\'épargne');
  String get addGoal => _t('هدف جديد', 'Nouvel objectif');
  String get editGoal => _t('تعديل الهدف', 'Modifier l\'objectif');
  String get goalName => _t('اسم الهدف', 'Nom de l\'objectif');
  String get targetAmount => _t('المبلغ المطلوب', 'Montant visé');
  String get savedAmount => _t('المدخر', 'Déjà épargné');
  String get deposit => _t('إيداع', 'Verser');
  String get withdraw => _t('سحب', 'Retirer');
  String get depositSaved => _t('تم الإيداع', 'Versement enregistré');
  String get withdrawSaved => _t('تم السحب', 'Retrait enregistré');
  String get goalSaved => _t('تم حفظ الهدف', 'Objectif enregistré');
  String get goalDeleted => _t('تم حذف الهدف', 'Objectif supprimé');
  String get noGoalsYet => _t('لا توجد أهداف بعد', 'Aucun objectif');
  String get goalCompleted => _t('تم الوصول للهدف', 'Objectif atteint');
  String get goalProgress => _t('التقدم', 'Progression');
  String get remainingForGoal => _t('يتبقى لك', 'Il vous reste');
  String get withdrawAmountCantExceed =>
      _t('المبلغ أكبر من المدخر', 'Le montant dépasse l\'épargne');
  String get depositFromAccount =>
      _t('خصم المبلغ من الحساب', 'Retirer le montant du compte');
  String get depositAmountCantExceed =>
      _t('المبلغ أكبر من رصيد الحساب', 'Le montant dépasse le solde du compte');
  String get deleteGoalConfirm => _t(
    'حذف هذا الهدف؟ لا يمكن التراجع.',
    'Supprimer cet objectif ? Action irréversible.',
  );
  String get goalDeadline =>
      _t('الموعد النهائي (اختياري)', 'Échéance (facultatif)');

  // ----------------------------------------------------------- dart (دورات)
  String get dartGroups => _t('الدَّارات', 'Dawras');
  String get addDart => _t('دَّارة جديدة', 'Nouvelle dawra');
  String get editDart => _t('تعديل الدَّارة', 'Modifier la dawra');
  String get dartName => _t('اسم الدَّارة', 'Nom de la dawra');
  String get contributionAmount => _t('القسط الشهري', 'Cotisation');
  String get contributionPaid => _t('تم تسجيل القسط', 'Cotisation enregistrée');
  String get memberCount => _t('عدد الأعضاء', 'Nombre de membres');
  String get members => _t('الأعضاء', 'Membres');
  String get memberName => _t('اسم العضو', 'Nom du membre');
  String get currentRound => _t('الجولة الحالية', 'Tour en cours');
  String get round => _t('جولة', 'Tour');
  String get payContribution => _t('أدِّي القسط', 'Payer la cotisation');
  String get markReceived => _t('تم الاستلام', 'Montant reçu');
  String get receiveRound => _t('استلمت المبلغ', 'J\'ai reçu le montant');
  String get recordSomeoneReceived =>
      _t('سجّل استلام عضو آخر', 'Enregistrer la réception d\'un autre');
  String get dartSaved => _t('تم حفظ الدَّارة', 'Dawra enregistrée');
  String get dartDeleted => _t('تم حذف الدَّارة', 'Dawra supprimée');
  String get noDartYet => _t('لا توجد دورات بعد', 'Aucune dawra');
  String get nextReceiver => _t('المستلم القادم', 'Prochain bénéficiaire');
  String get iAm => _t('أنا', 'Moi');
  String get paidStatus => _t('أدّى', 'Payé');
  String get notPaid => _t('لم يؤدِّ', 'Non payé');
  String get totalPot => _t('المنحة الكاملة', 'Cagnotte totale');
  String get roundsDone => _t('جولات منجزة', 'tours terminés');
  String get roundN => _t('الجولة رقم', 'Tour n°');
  String get dartPaymentsHint => _t(
    'يدفع كل عضو قسطه شهرياً، ويستلم المنحة حسب ترتيب الجولات',
    'Chaque membre paie sa cotisation et reçoit la cagnotte à tour de rôle',
  );
  String get deleteDartConfirm => _t(
    'حذف هذه الدَّارة؟ لا يمكن التراجع.',
    'Supprimer cette dawra ? Action irréversible.',
  );
  String get alreadyPaidThisRound =>
      _t('أدّيت قسط هذه الجولة', 'Cotisation déjà payée ce tour');
  String get roundComplete => _t(
    'انتهت الجولة — تقدم للجولة التالية',
    'Tour terminé — passez au suivant',
  );
  String get membersHint => _t(
    'افصل بين الأسماء بفاصلة. اجعل نفسك في القائمة.',
    'Séparez les noms par des virgules. Incluez-vous dans la liste.',
  );
  String get dartMembersRequired =>
      _t('أضف عضوين على الأقل', 'Ajoutez au moins 2 membres');
  String get paidLabel => _t('أدّى', 'Payé');

  // ------------------------------------------------------- seasonal (موسمي)
  String get seasonal => _t('التخطيط الموسمي', 'Planification saisonnière');
  String get seasonalHint => _t(
    'حضّر مصاريف رمضان والعودة للمدرسة والعطل مبكراً',
    'Préparez à l\'avance le Ramadan, la rentrée et les vacances',
  );
  String get monthlySetAside => _t('ادخر شهرياً', 'Épargne mensuelle');
  String get eventRamadan => _t('بداية رمضان', 'Début du Ramadan');
  String get eventEid => _t('عيد الفطر', 'Aïd el-Fitr');
  String get eventSchoolYear => _t('العودة للمدرسة', 'Rentrée scolaire');
  String get eventSummer => _t('العطلة الصيفية', 'Vacances d\'été');
  String get eventNovember => _t('الثامن من نوفمبر', '1er Novembre');
  String get eventNewYear => _t('رأس السنة', 'Nouvel An');
  String get createGoalForEvent =>
      _t('أنشئ هدفاً لهذا المناسب', 'Créer un objectif pour cet événement');
  String get seasonalGoalName => _t('اسم هدف التحضير', 'Nom de l\'objectif');
  String get amountHintOptional =>
      _t('المبلغ التقديري (اختياري)', 'Montant estimé (facultatif)');
  String get noUpcomingEvents =>
      _t('لا توجد مناسبات قادمة', 'Aucun événement à venir');
  String get seasonalGoals => _t('أهداف التحضير', 'Objectifs de préparation');

  // ------------------------------------------------------------- reports
  String get reports => _t('التقارير', 'Rapports');
  String get exportExcel => _t('تصدير Excel', 'Exporter Excel');
  String get exportPdf => _t('تصدير PDF', 'Exporter PDF');
  String get reportIncome => _t('إجمالي الدخل', 'Total des revenus');
  String get reportExpense => _t('إجمالي المصاريف', 'Total des dépenses');
  String get reportNet => _t('الصافي', 'Épargne nette');
  String get reportByCategory => _t('حسب الفئة', 'Par catégorie');
  String get reportOperations => _t('العمليات', 'Opérations');
  String get exportDone => _t('تم تجهيز الملف', 'Fichier prêt');
  String get exportFailed => _t('تعذّر التصدير', 'Échec de l\'export');
  String get reportEmpty =>
      _t('لا توجد بيانات لهذا الشهر', 'Aucune donnée ce mois');
  String get month => _t('الشهر', 'Mois');
  String get count => _t('العدد', 'Nombre');

  // ------------------------------------------------- automatic ledger notes
  String debtPaymentReceivedNote(String person) =>
      _t('دفعة من دين لي — $person', 'Remboursement reçu — $person');
  String debtPaymentPaidNote(String person) =>
      _t('دفعة لدين عليّ — $person', 'Remboursement versé — $person');
  String dawraContributionNote(String group, String member, int round) => _t(
    'دَّارة $group — $member (جولة $round)',
    'Dawra $group — $member (tour $round)',
  );
  String dawraPotNote(String group, String receiver, int round) => _t(
    'دَّارة $group — استلام $receiver (جولة $round)',
    'Dawra $group — remise à $receiver (tour $round)',
  );

  // ------------------------------------------------------------- my data
  String get myData => _t('بياناتي', 'Mes données');
  String get exportBackup =>
      _t('تصدير نسخة احتياطية', 'Exporter une sauvegarde');
  String get exportBackupHint => _t(
    'ملف JSON يحتوي كل حساباتك وعملياتك وديونك واشتراكاتك وأهدافك',
    'Fichier JSON avec tous vos comptes, opérations, dettes, abonnements et objectifs',
  );
  String get deleteUserAccount =>
      _t('حذف حسابي نهائياً', 'Supprimer mon compte');
  String get deleteUserAccountHint => _t(
    'يحذف كل بياناتك من الخادم ولا يمكن التراجع عنه',
    'Efface toutes vos données du serveur, définitivement',
  );
  String get deleteUserAccountConfirm => _t(
    'سيتم حذف حسابك وكل بياناتك (العمليات، الحسابات، الديون، الاشتراكات، الأهداف، الدَّارات) نهائياً. ننصحك بتصدير نسخة احتياطية أولاً. متابعة؟',
    'Votre compte et toutes vos données (opérations, comptes, dettes, abonnements, objectifs, dawras) seront supprimés définitivement. Exportez d’abord une sauvegarde. Continuer ?',
  );
  String get confirmWithPassword =>
      _t('أدخل كلمة المرور للتأكيد', 'Saisissez votre mot de passe');
  String get deletingAccount =>
      _t('جارٍ حذف الحساب…', 'Suppression du compte…');
  String get accountDeleted =>
      _t('تم حذف حسابك', 'Votre compte a été supprimé');

  // ---------------------------------------------------------------- misc
  String get inPlus => _t('خلال', 'sur');
  String get openIn => _t('فتح في', 'Ouvrir dans');
  String get setupRequiredTitle =>
      _t('Firebase غير مهيّأ', 'Firebase non configuré');
  String get setupRequiredBody => _t(
    'شغّل الأمرين التاليين في جذر المشروع ثم أعد تشغيل التطبيق:\n\ndart pub global activate flutterfire_cli\nflutterfire configure',
    'Exécutez ces deux commandes à la racine du projet puis relancez l\'application :\n\ndart pub global activate flutterfire_cli\nflutterfire configure',
  );
}
