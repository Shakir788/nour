import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_background.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _selectedLang = 'English';

  final List<String> _languages = [
    'English',
    'العربية', // Arabic
    'Français', // French
    'Español', // Spanish
    'Русский' // Russian
  ];

  // Full Translations exactly as per your beautiful concept
  final Map<String, Map<String, String>> _localizedText = {
    'English': {
      'heroTitle': 'The Heart Behind NOUR',
      'sec1Title': 'A Small Gift, With a Heartfelt Purpose',
      'sec1Subtitle': 'A little light, a little peace, and a purpose beyond ourselves.',
      'sec1Body': 'Every meaningful journey begins with a simple intention. NOUR was born from a desire to create something that goes beyond technology. Something that offers a little peace in a busy world, a gentle reminder in difficult moments, and a quiet space for reflection, gratitude, and spiritual growth.\n\nI am not building this with the belief that I have all the answers. I am building it with the hope that even a small effort, made with sincerity, can make someone\'s day a little lighter.',
      'sec2Title': 'A Prayer That Lives Beyond Us',
      'sec2Quote': '"Some gifts are not measured by their size, but by the love and intention behind them."',
      'sec2Body': 'NOUR is a humble offering, created with the hope that its benefits may become a source of ongoing good. At the heart of this effort is a prayer for my late father, whose memory remains a part of my journey.\n\nMay every moment of peace, every beneficial reminder, and every act of goodness inspired by this little creation become a means of mercy and reward.\n\nMay Allah have mercy on those who have returned to Him, forgive their shortcomings, illuminate their resting places, and accept every sincere act of goodness done in their memory. Ameen.',
      'valTitle': 'What NOUR Stands For',
      'val1Head': 'Compassion',
      'val1Desc': 'Technology should feel human. NOUR aims to offer gentle support, understanding, and encouragement without judgment.',
      'val2Head': 'Spiritual Connection',
      'val2Desc': 'A quiet space for prayer, reflection, remembrance, and reconnecting with what truly matters.',
      'val3Head': 'Everyday Well-being',
      'val3Desc': 'Helping people build healthier routines, find moments of calm, and make room for themselves.',
      'val4Head': 'Sincere Giving',
      'val4Desc': 'Creating something useful for others, hoping its goodness continues beyond the person who made it.',
      'msgTitle': 'A Message To You',
      'msgBody': 'If you have found your way here, I hope NOUR brings something meaningful into your life. Perhaps it is a peaceful moment before sleep, a reminder when your heart feels distant, a little encouragement on a difficult day, or simply a space where you can slow down and breathe.\n\nYou do not have to be perfect to begin again. Every small step toward peace, kindness, and a better version of yourself matters.\n\nThank you for being a part of this journey. Your presence gives this humble effort a purpose beyond its creator.',
      'footerQuote': '"May this little light reach places I never will."',
      'footerTagline': 'Made with sincerity. Shared with hope. Remembered in prayer.',
    },
    'العربية': {
      'heroTitle': 'القلب النابض خلف نور',
      'sec1Title': 'هدية صغيرة، بهدف نابع من القلب',
      'sec1Subtitle': 'قليل من النور، قليل من السلام، وغاية تتجاوز أنفسنا.',
      'sec1Body': 'كل رحلة ذات مغزى تبدأ بنية بسيطة. وُلد "نور" من رغبة في خلق شيء يتجاوز مجرد التكنولوجيا. شيء يقدم القليل من السلام في عالم مزدحم، وتذكيراً لطيفاً في اللحظات الصعبة، ومساحة هادئة للتأمل والامتنان والنمو الروحي.\n\nأنا لا أبني هذا لاعتقادي بأنني أملك كل الإجابات. بل أبنيه على أمل أن حتى الجهد الصغير، المبذول بإخلاص، يمكن أن يجعل يوم شخص ما أكثر إشراقاً.',
      'sec2Title': 'دعاء يعيش بعدنا',
      'sec2Quote': '"بعض الهدايا لا تُقاس بحجمها، بل بالحب والنوايا التي تقف خلفها."',
      'sec2Body': '"نور" هو عطاء متواضع، صُنع بأمل أن تصبح فوائده مصدراً لخير مستمر. في قلب هذا الجهد يكمن دعاء لوالدي المرحوم، الذي تظل ذكراه جزءاً من رحلتي.\n\nعسى أن تكون كل لحظة سلام، وكل تذكير نافع، وكل عمل خير يُلهم به هذا الإبداع الصغير سبباً للرحمة والأجر.\n\nرحم الله من عادوا إليه، وتجاوز عن زلاتهم، وأنار قبورهم، وتقبل كل عمل خير صُنع بصدق في ذكراهم. آمين.',
      'valTitle': 'ما يمثله نور',
      'val1Head': 'الرحمة',
      'val1Desc': 'يجب أن تبدو التكنولوجيا إنسانية. يهدف "نور" إلى تقديم الدعم اللطيف والتفهم دون إطلاق أحكام.',
      'val2Head': 'الاتصال الروحي',
      'val2Desc': 'مساحة هادئة للصلاة، والتأمل، والذكر، وإعادة الاتصال بما يهم حقاً.',
      'val3Head': 'الرفاهية اليومية',
      'val3Desc': 'مساعدة الناس على بناء عادات صحية، وإيجاد لحظات من الهدوء، وتخصيص وقت لأنفسهم.',
      'val4Head': 'العطاء الصادق',
      'val4Desc': 'صنع شيء مفيد للآخرين، على أمل أن يستمر خيره ليتجاوز الشخص الذي صنعه.',
      'msgTitle': 'رسالة إليك',
      'msgBody': 'إذا وصلت إلى هنا، أتمنى أن يضيف "نور" شيئاً ذا معنى إلى حياتك. ربما تكون لحظة هادئة قبل النوم، أو تذكيراً عندما تشعر ببعد قلبك، أو تشجيعاً في يوم صعب.\n\nليس عليك أن تكون مثالياً لتبدأ من جديد. كل خطوة صغيرة نحو السلام واللطف تهم.\n\nشكراً لكونك جزءاً من هذه الرحلة. وجودك يمنح هذا الجهد المتواضع غاية تتجاوز صانعه.',
      'footerQuote': '"عسى أن يصل هذا النور الصغير إلى أماكن لن أصل إليها أبدًا."',
      'footerTagline': 'صُنع بصدق. شُورك بأمل. ذُكر في دعاء.',
    },
    'Français': {
      'heroTitle': 'Le Cœur Derrière NOUR',
      'sec1Title': 'Un Petit Cadeau, Un But Sincère',
      'sec1Subtitle': 'Un peu de lumière, un peu de paix, et un but au-delà de nous-mêmes.',
      'sec1Body': 'Chaque voyage significatif commence par une simple intention. NOUR est né du désir de créer quelque chose qui va au-delà de la technologie. Quelque chose qui offre un peu de paix dans un monde occupé.\n\nJe ne construis pas cela en croyant avoir toutes les réponses, mais avec l\'espoir qu\'un petit effort, fait avec sincérité, puisse alléger la journée de quelqu\'un.',
      'sec2Title': 'Une Prière Qui Nous Survit',
      'sec2Quote': '"Certains cadeaux ne se mesurent pas par leur taille, mais par l\'amour et l\'intention qui les accompagnent."',
      'sec2Body': 'NOUR est une humble offrande, créée avec l\'espoir que ses bienfaits deviennent une source de bien continu. Au cœur de cet effort se trouve une prière pour mon défunt père.\n\nQue chaque moment de paix et chaque acte de bonté inspiré par cette création devienne un moyen de miséricorde.\n\nQu\'Allah fasse miséricorde à ceux qui sont retournés à Lui, illumine leurs lieux de repos et accepte chaque bonne action faite en leur mémoire. Amine.',
      'valTitle': 'Ce Que Représente NOUR',
      'val1Head': 'Compassion',
      'val1Desc': 'La technologie doit être humaine. NOUR offre un soutien doux et sans jugement.',
      'val2Head': 'Connexion Spirituelle',
      'val2Desc': 'Un espace calme pour la prière, la réflexion et le souvenir.',
      'val3Head': 'Bien-être Quotidien',
      'val3Desc': 'Aider à construire des routines saines et trouver des moments de calme.',
      'val4Head': 'Don Sincère',
      'val4Desc': 'Créer quelque chose d\'utile dont la bonté perdure au-delà de son créateur.',
      'msgTitle': 'Un Message Pour Vous',
      'msgBody': 'Si vous êtes arrivé jusqu\'ici, j\'espère que NOUR apportera quelque chose de significatif dans votre vie. Chaque petit pas vers la paix et la gentillesse compte.\n\nMerci de faire partie de ce voyage. Votre présence donne à cet humble effort un but au-delà de son créateur.',
      'footerQuote': '"Que cette petite lumière atteigne des endroits que je n\'atteindrai jamais."',
      'footerTagline': 'Fait avec sincérité. Partagé avec espoir. Rappelé en prière.',
    },
    'Español': {
      'heroTitle': 'El Corazón Detrás de NOUR',
      'sec1Title': 'Un Pequeño Regalo, Con un Propósito Sincero',
      'sec1Subtitle': 'Un poco de luz, un poco de paz y un propósito más allá de nosotros mismos.',
      'sec1Body': 'Todo viaje significativo comienza con una intención simple. NOUR nació del deseo de crear algo que vaya más allá de la tecnología.\n\nNo construyo esto creyendo tener todas las respuestas, sino con la esperanza de que un pequeño esfuerzo hecho con sinceridad pueda alegrar el día de alguien.',
      'sec2Title': 'Una Oración Que Perdura',
      'sec2Quote': '"Algunos regalos no se miden por su tamaño, sino por el amor y la intención detrás de ellos."',
      'sec2Body': 'NOUR es una ofrenda humilde, creada con la esperanza de que sea una fuente de bien continuo. En el corazón de este esfuerzo hay una oración por mi difunto padre.\n\nQue Alá tenga misericordia de quienes han regresado a Él, ilumine sus lugares de descanso y acepte cada acto de bondad en su memoria. Amén.',
      'valTitle': 'Lo Que Representa NOUR',
      'val1Head': 'Compasión',
      'val1Desc': 'La tecnología debe sentirse humana. Apoyo suave y sin prejuicios.',
      'val2Head': 'Conexión Espiritual',
      'val2Desc': 'Un espacio tranquilo para la oración, la reflexión y el recuerdo.',
      'val3Head': 'Bienestar Diario',
      'val3Desc': 'Ayudar a las personas a encontrar momentos de calma.',
      'val4Head': 'Dar con Sinceridad',
      'val4Desc': 'Crear algo útil esperando que su bondad continúe.',
      'msgTitle': 'Un Mensaje Para Ti',
      'msgBody': 'Si has llegado hasta aquí, espero que NOUR aporte algo significativo a tu vida. No tienes que ser perfecto para empezar de nuevo.\n\nGracias por ser parte de este viaje.',
      'footerQuote': '"Que esta pequeña luz llegue a lugares que yo nunca alcanzaré."',
      'footerTagline': 'Hecho con sinceridad. Compartido con esperanza. Recordado en oración.',
    },
    'Русский': {
      'heroTitle': 'Сердце NOUR',
      'sec1Title': 'Небольшой Подарок с Искренней Целью',
      'sec1Subtitle': 'Немного света, немного покоя и цель, выходящая за пределы нас самих.',
      'sec1Body': 'Каждое значимое путешествие начинается с простого намерения. NOUR родился из желания создать нечто большее, чем просто технология.\n\nЯ создаю это с надеждой, что даже небольшое усилие, сделанное искренне, может сделать чей-то день светлее.',
      'sec2Title': 'Молитва, Живущая Дольше Нас',
      'sec2Quote': '"Некоторые подарки измеряются не размером, а любовью и намерением."',
      'sec2Body': 'В основе этих усилий лежит молитва за моего покойного отца.\n\nПусть Аллах смилостивится над теми, кто вернулся к Нему, простит их недостатки, осветит их места упокоения и примет каждый добрый поступок в их память. Аминь.',
      'valTitle': 'Ценности NOUR',
      'val1Head': 'Сострадание',
      'val1Desc': 'Технологии должны быть человечными. Мягкая поддержка без осуждения.',
      'val2Head': 'Духовная Связь',
      'val2Desc': 'Тихое пространство для молитвы и размышлений.',
      'val3Head': 'Ежедневное Благополучие',
      'val3Desc': 'Помощь в поиске моментов спокойствия.',
      'val4Head': 'Искренняя Отдача',
      'val4Desc': 'Создание полезного с надеждой на продолжение добра.',
      'msgTitle': 'Послание Вам',
      'msgBody': 'Спасибо, что стали частью этого пути. Ваше присутствие придает этому скромному труду смысл, выходящий за рамки его создателя.',
      'footerQuote': '"Пусть этот маленький свет достигнет мест, куда я никогда не доберусь."',
      'footerTagline': 'Сделано искренне. Поделено с надеждой. Вспомнено в молитве.',
    }
  };

  Widget _buildValueItem(String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _localizedText[_selectedLang]!;
    final isRTL = _selectedLang == 'العربية';

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(CupertinoIcons.back, color: AppColors.gold),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(CupertinoIcons.globe, color: AppColors.gold),
              color: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (String lang) {
                setState(() {
                  _selectedLang = lang;
                });
              },
              itemBuilder: (BuildContext context) {
                return _languages.map((String lang) {
                  return PopupMenuItem<String>(
                    value: lang,
                    child: Text(
                      lang,
                      style: TextStyle(
                        color: _selectedLang == lang ? AppColors.gold : Colors.white,
                        fontWeight: _selectedLang == lang ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),
        body: Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Hero Section
                const Icon(CupertinoIcons.moon_stars_fill, size: 50, color: AppColors.gold),
                const SizedBox(height: 16),
                Text(
                  t['heroTitle']!,
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 28, color: AppColors.gold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // 2. Story Section (No GlassCard, Just clean text)
                Align(
                  alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    t['sec1Title']!,
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    t['sec1Subtitle']!,
                    style: const TextStyle(color: AppColors.gold, fontStyle: FontStyle.italic, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t['sec1Body']!,
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70, height: 1.6),
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                ),
                const SizedBox(height: 40),

                // 3. Remembrance Section (Highlighted in GlassCard)
                GlassCard(
                  opacity: 0.4,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.heart_fill, color: AppColors.gold, size: 30),
                      const SizedBox(height: 16),
                      Text(
                        t['sec2Title']!,
                        style: AppTextStyles.displayMedium.copyWith(fontSize: 22, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t['sec2Quote']!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gold, 
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t['sec2Body']!,
                        style: AppTextStyles.bodyLarge.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 4. Values Section
                Align(
                  alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    t['valTitle']!,
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                _buildValueItem(t['val1Head']!, t['val1Desc']!, CupertinoIcons.heart),
                _buildValueItem(t['val2Head']!, t['val2Desc']!, CupertinoIcons.sparkles),
                _buildValueItem(t['val3Head']!, t['val3Desc']!, CupertinoIcons.leaf_arrow_circlepath),
                _buildValueItem(t['val4Head']!, t['val4Desc']!, CupertinoIcons.gift),
                
                const SizedBox(height: 20),
                Divider(color: AppColors.gold.withValues(alpha: 0.2)),
                const SizedBox(height: 30),

                // 5. Message Section
                Text(
                  t['msgTitle']!,
                  style: AppTextStyles.displayMedium.copyWith(fontSize: 22, color: AppColors.gold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  t['msgBody']!,
                  style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),

                // 6. The Intention Footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.surfaceElevated.withValues(alpha: 0.3),
                  ),
                  child: Column(
                    children: [
                      Text(
                        t['footerQuote']!,
                        style: AppTextStyles.displayMedium.copyWith(
                          fontSize: 18, 
                          color: Colors.white,
                          fontStyle: FontStyle.italic
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t['footerTagline']!,
                        style: const TextStyle(color: AppColors.gold, fontSize: 13, letterSpacing: 1),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}