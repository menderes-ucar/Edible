// GENERATED from the reviewed phrase table. Phrases shown to restaurant staff.
//
// Each language contains: a title, an allergy introduction, one noun phrase per
// allergen, a closing sentence about cross-contamination, diet sentences and a
// thank-you line. Falls back to English for unsupported languages.
import 'entities/dietary_profile.dart';
import 'entities/food_filter.dart';

class WaiterPhrases {
  const WaiterPhrases({
    required this.title,
    required this.allergyIntro,
    required this.allergyOutro,
    required this.dietIntro,
    required this.thanks,
    required this.allergens,
    required this.diets,
  });

  final String title;
  final String allergyIntro;
  final String allergyOutro;
  final String dietIntro;
  final String thanks;
  final Map<Allergen, String> allergens;
  final Map<FoodFilter, String> diets;
}

WaiterPhrases waiterPhrasesFor(String languageCode) =>
    _phrases[languageCode] ?? _phrases['en']!;

String waiterListSeparator(String languageCode) => switch (languageCode) {
      'ar' => '، ',
      'zh' || 'ja' => '、',
      _ => ', ',
    };

/// Best-guess local language for a destination, limited to the languages the
/// card supports. Anything else falls back to English, which most restaurant
/// staff in tourist areas understand better than the user's own language.
String waiterLanguageForCountry(String? countryCode) {
  final code = (countryCode ?? '').trim().toUpperCase();
  const byLanguage = <String, Set<String>>{
    'tr': {'TR'},
    'de': {'DE', 'AT', 'CH', 'LI'},
    'fr': {'FR', 'MC', 'LU'},
    'es': {'ES', 'MX', 'AR', 'CL', 'CO', 'PE', 'VE', 'EC', 'BO', 'PY', 'UY', 'CR', 'PA', 'DO', 'GT', 'HN', 'NI', 'SV', 'CU'},
    'it': {'IT', 'SM', 'VA'},
    'ar': {'SA', 'AE', 'EG', 'MA', 'DZ', 'TN', 'JO', 'LB', 'KW', 'QA', 'OM', 'BH', 'IQ', 'SY', 'LY', 'YE', 'PS'},
    'zh': {'CN', 'TW', 'HK', 'MO'},
    'ru': {'RU', 'BY', 'KZ', 'KG'},
    'ko': {'KR', 'KP'},
    'ja': {'JP'},
    'pt': {'PT', 'BR', 'AO', 'MZ'},
    'nl': {'NL', 'SR'},
  };
  for (final entry in byLanguage.entries) {
    if (entry.value.contains(code)) return entry.key;
  }
  return 'en';
}

const _phrases = <String, WaiterPhrases>{
  'en': WaiterPhrases(
    title: "Please read: my food allergies and diet",
    allergyIntro: "I have a serious food allergy. I must not eat:",
    allergyOutro: "Please make sure my meal contains none of these, including hidden ingredients, shared cooking oil or shared surfaces.",
    dietIntro: "I also follow these dietary rules:",
    thanks: "Thank you very much for your help!",
    allergens: {
      Allergen.peanuts: "peanuts",
      Allergen.treeNuts: "tree nuts (almonds, hazelnuts, walnuts, cashews, pistachios)",
      Allergen.milk: "milk and dairy products",
      Allergen.eggs: "eggs",
      Allergen.gluten: "gluten (wheat, barley, rye)",
      Allergen.soy: "soy",
      Allergen.fish: "fish",
      Allergen.shellfish: "shellfish (shrimp, crab, lobster, mussels)",
      Allergen.sesame: "sesame",
    },
    diets: {
      FoodFilter.vegan: "I do not eat any animal products: no meat, fish, dairy, eggs or honey.",
      FoodFilter.vegetarian: "I do not eat meat or fish.",
      FoodFilter.halal: "I eat only halal food.",
      FoodFilter.noPork: "I do not eat pork or anything made with pork, including lard and gelatin.",
      FoodFilter.noAlcohol: "I do not consume alcohol, including in cooking.",
    },
  ),
  'tr': WaiterPhrases(
    title: "Lütfen okuyun: gıda alerjilerim ve beslenme düzenim",
    allergyIntro: "Ciddi bir gıda alerjim var. Şunları kesinlikle yiyemem:",
    allergyOutro: "Lütfen yemeğimde bunlardan hiçbirinin olmadığından emin olun; gizli içerikler, ortak kullanılan yağ ve ortak yüzeyler dahil.",
    dietIntro: "Ayrıca şu beslenme kurallarına uyuyorum:",
    thanks: "Yardımınız için çok teşekkür ederim!",
    allergens: {
      Allergen.peanuts: "yer fıstığı",
      Allergen.treeNuts: "sert kabuklu yemişler (badem, fındık, ceviz, kaju, antep fıstığı)",
      Allergen.milk: "süt ve süt ürünleri",
      Allergen.eggs: "yumurta",
      Allergen.gluten: "gluten (buğday, arpa, çavdar)",
      Allergen.soy: "soya",
      Allergen.fish: "balık",
      Allergen.shellfish: "kabuklu deniz ürünleri (karides, yengeç, ıstakoz, midye)",
      Allergen.sesame: "susam",
    },
    diets: {
      FoodFilter.vegan: "Hiçbir hayvansal ürün yemem: et, balık, süt ürünü, yumurta veya bal yok.",
      FoodFilter.vegetarian: "Et ve balık yemem.",
      FoodFilter.halal: "Yalnızca helal yiyecek yerim.",
      FoodFilter.noPork: "Domuz eti ve domuz içeren hiçbir şeyi yemem; domuz yağı ve jelatin dahil.",
      FoodFilter.noAlcohol: "Alkol tüketmem; yemeklerde pişirmede kullanılan alkol dahil.",
    },
  ),
  'de': WaiterPhrases(
    title: "Bitte lesen: meine Nahrungsmittelallergien und Ernährungsweise",
    allergyIntro: "Ich habe eine schwere Nahrungsmittelallergie. Ich darf nicht essen:",
    allergyOutro: "Bitte stellen Sie sicher, dass mein Essen nichts davon enthält – auch keine versteckten Zutaten, gemeinsam genutztes Frittieröl oder gemeinsame Arbeitsflächen.",
    dietIntro: "Außerdem halte ich folgende Ernährungsregeln ein:",
    thanks: "Vielen Dank für Ihre Hilfe!",
    allergens: {
      Allergen.peanuts: "Erdnüsse",
      Allergen.treeNuts: "Schalenfrüchte (Mandeln, Haselnüsse, Walnüsse, Cashews, Pistazien)",
      Allergen.milk: "Milch und Milchprodukte",
      Allergen.eggs: "Eier",
      Allergen.gluten: "Gluten (Weizen, Gerste, Roggen)",
      Allergen.soy: "Soja",
      Allergen.fish: "Fisch",
      Allergen.shellfish: "Krusten- und Schalentiere (Garnelen, Krabben, Hummer, Muscheln)",
      Allergen.sesame: "Sesam",
    },
    diets: {
      FoodFilter.vegan: "Ich esse keine tierischen Produkte: kein Fleisch, keinen Fisch, keine Milchprodukte, keine Eier und keinen Honig.",
      FoodFilter.vegetarian: "Ich esse weder Fleisch noch Fisch.",
      FoodFilter.halal: "Ich esse nur halal.",
      FoodFilter.noPork: "Ich esse kein Schweinefleisch und nichts, was damit hergestellt wurde, auch kein Schmalz und keine Gelatine.",
      FoodFilter.noAlcohol: "Ich konsumiere keinen Alkohol, auch nicht zum Kochen.",
    },
  ),
  'fr': WaiterPhrases(
    title: "Merci de lire : mes allergies alimentaires et mon régime",
    allergyIntro: "J'ai une allergie alimentaire grave. Je ne dois pas manger :",
    allergyOutro: "Merci de vous assurer que mon repas n'en contient aucun, y compris sous forme d'ingrédients cachés, d'huile de cuisson partagée ou de surfaces partagées.",
    dietIntro: "Je suis également ces règles alimentaires :",
    thanks: "Merci beaucoup pour votre aide !",
    allergens: {
      Allergen.peanuts: "arachides (cacahuètes)",
      Allergen.treeNuts: "fruits à coque (amandes, noisettes, noix, noix de cajou, pistaches)",
      Allergen.milk: "lait et produits laitiers",
      Allergen.eggs: "œufs",
      Allergen.gluten: "gluten (blé, orge, seigle)",
      Allergen.soy: "soja",
      Allergen.fish: "poisson",
      Allergen.shellfish: "crustacés et mollusques (crevettes, crabe, homard, moules)",
      Allergen.sesame: "sésame",
    },
    diets: {
      FoodFilter.vegan: "Je ne mange aucun produit animal : ni viande, ni poisson, ni produits laitiers, ni œufs, ni miel.",
      FoodFilter.vegetarian: "Je ne mange ni viande ni poisson.",
      FoodFilter.halal: "Je ne mange que de la nourriture halal.",
      FoodFilter.noPork: "Je ne mange pas de porc ni rien qui en contienne, y compris le saindoux et la gélatine.",
      FoodFilter.noAlcohol: "Je ne consomme pas d'alcool, y compris dans la cuisine.",
    },
  ),
  'es': WaiterPhrases(
    title: "Por favor, lea: mis alergias alimentarias y mi dieta",
    allergyIntro: "Tengo una alergia alimentaria grave. No puedo comer:",
    allergyOutro: "Por favor, asegúrese de que mi comida no contenga nada de esto, incluidos ingredientes ocultos, aceite de cocina compartido o superficies compartidas.",
    dietIntro: "Además sigo estas normas alimentarias:",
    thanks: "¡Muchas gracias por su ayuda!",
    allergens: {
      Allergen.peanuts: "cacahuetes (maní)",
      Allergen.treeNuts: "frutos secos (almendras, avellanas, nueces, anacardos, pistachos)",
      Allergen.milk: "leche y productos lácteos",
      Allergen.eggs: "huevos",
      Allergen.gluten: "gluten (trigo, cebada, centeno)",
      Allergen.soy: "soja",
      Allergen.fish: "pescado",
      Allergen.shellfish: "mariscos (gambas, cangrejo, langosta, mejillones)",
      Allergen.sesame: "sésamo",
    },
    diets: {
      FoodFilter.vegan: "No como ningún producto de origen animal: ni carne, ni pescado, ni lácteos, ni huevos, ni miel.",
      FoodFilter.vegetarian: "No como carne ni pescado.",
      FoodFilter.halal: "Solo como comida halal.",
      FoodFilter.noPork: "No como cerdo ni nada elaborado con cerdo, incluidos manteca y gelatina.",
      FoodFilter.noAlcohol: "No consumo alcohol, tampoco en la cocina.",
    },
  ),
  'it': WaiterPhrases(
    title: "Si prega di leggere: le mie allergie alimentari e la mia dieta",
    allergyIntro: "Ho una grave allergia alimentare. Non posso mangiare:",
    allergyOutro: "Vi prego di assicurarvi che il mio pasto non contenga nulla di tutto ciò, inclusi ingredienti nascosti, olio di cottura condiviso o superfici condivise.",
    dietIntro: "Seguo inoltre queste regole alimentari:",
    thanks: "Grazie mille per il vostro aiuto!",
    allergens: {
      Allergen.peanuts: "arachidi",
      Allergen.treeNuts: "frutta a guscio (mandorle, nocciole, noci, anacardi, pistacchi)",
      Allergen.milk: "latte e latticini",
      Allergen.eggs: "uova",
      Allergen.gluten: "glutine (frumento, orzo, segale)",
      Allergen.soy: "soia",
      Allergen.fish: "pesce",
      Allergen.shellfish: "crostacei e molluschi (gamberi, granchio, aragosta, cozze)",
      Allergen.sesame: "sesamo",
    },
    diets: {
      FoodFilter.vegan: "Non mangio prodotti di origine animale: niente carne, pesce, latticini, uova o miele.",
      FoodFilter.vegetarian: "Non mangio carne né pesce.",
      FoodFilter.halal: "Mangio solo cibo halal.",
      FoodFilter.noPork: "Non mangio maiale né nulla che lo contenga, compresi strutto e gelatina.",
      FoodFilter.noAlcohol: "Non consumo alcol, nemmeno in cottura.",
    },
  ),
  'ar': WaiterPhrases(
    title: "يُرجى القراءة: حساسية الطعام لديّ ونظامي الغذائي",
    allergyIntro: "لديّ حساسية غذائية شديدة. لا يجوز لي تناول:",
    allergyOutro: "يُرجى التأكد من أن وجبتي لا تحتوي على أيٍّ من هذه المكوّنات، بما في ذلك المكوّنات المخفية وزيت الطهي المشترك والأسطح المشتركة.",
    dietIntro: "كما ألتزم بالقواعد الغذائية التالية:",
    thanks: "شكرًا جزيلًا على مساعدتكم!",
    allergens: {
      Allergen.peanuts: "الفول السوداني",
      Allergen.treeNuts: "المكسرات (اللوز والبندق والجوز والكاجو والفستق)",
      Allergen.milk: "الحليب ومنتجات الألبان",
      Allergen.eggs: "البيض",
      Allergen.gluten: "الغلوتين (القمح والشعير والجاودار)",
      Allergen.soy: "الصويا",
      Allergen.fish: "السمك",
      Allergen.shellfish: "المحار والقشريات (الروبيان والسلطعون والكركند وبلح البحر)",
      Allergen.sesame: "السمسم",
    },
    diets: {
      FoodFilter.vegan: "لا آكل أي منتجات حيوانية: لا لحوم ولا أسماك ولا ألبان ولا بيض ولا عسل.",
      FoodFilter.vegetarian: "لا آكل اللحوم ولا الأسماك.",
      FoodFilter.halal: "لا آكل إلا الطعام الحلال.",
      FoodFilter.noPork: "لا آكل لحم الخنزير ولا أي شيء يحتوي عليه، بما في ذلك الشحم والجيلاتين.",
      FoodFilter.noAlcohol: "لا أتناول الكحول، بما في ذلك الكحول المستخدم في الطهي.",
    },
  ),
  'zh': WaiterPhrases(
    title: "请阅读：我的食物过敏和饮食要求",
    allergyIntro: "我有严重的食物过敏。我绝对不能吃：",
    allergyOutro: "请确保我的餐食不含上述任何成分，包括隐藏成分、共用的烹饪油或共用的操作台面。",
    dietIntro: "我还遵守以下饮食规则：",
    thanks: "非常感谢您的帮助！",
    allergens: {
      Allergen.peanuts: "花生",
      Allergen.treeNuts: "坚果（杏仁、榛子、核桃、腰果、开心果）",
      Allergen.milk: "牛奶及乳制品",
      Allergen.eggs: "鸡蛋",
      Allergen.gluten: "麸质（小麦、大麦、黑麦）",
      Allergen.soy: "大豆",
      Allergen.fish: "鱼类",
      Allergen.shellfish: "贝类和甲壳类（虾、蟹、龙虾、贻贝）",
      Allergen.sesame: "芝麻",
    },
    diets: {
      FoodFilter.vegan: "我不吃任何动物制品：不吃肉、鱼、乳制品、鸡蛋或蜂蜜。",
      FoodFilter.vegetarian: "我不吃肉和鱼。",
      FoodFilter.halal: "我只吃清真食品。",
      FoodFilter.noPork: "我不吃猪肉及任何含猪肉的食品，包括猪油和明胶。",
      FoodFilter.noAlcohol: "我不摄入酒精，包括烹饪中使用的酒。",
    },
  ),
  'ru': WaiterPhrases(
    title: "Пожалуйста, прочитайте: моя пищевая аллергия и диета",
    allergyIntro: "У меня серьёзная пищевая аллергия. Мне нельзя есть:",
    allergyOutro: "Пожалуйста, убедитесь, что в моём блюде нет ничего из этого, включая скрытые ингредиенты, общее масло для готовки и общие рабочие поверхности.",
    dietIntro: "Я также соблюдаю следующие правила питания:",
    thanks: "Большое спасибо за помощь!",
    allergens: {
      Allergen.peanuts: "арахис",
      Allergen.treeNuts: "орехи (миндаль, фундук, грецкие орехи, кешью, фисташки)",
      Allergen.milk: "молоко и молочные продукты",
      Allergen.eggs: "яйца",
      Allergen.gluten: "глютен (пшеница, ячмень, рожь)",
      Allergen.soy: "соя",
      Allergen.fish: "рыба",
      Allergen.shellfish: "моллюски и ракообразные (креветки, краб, омар, мидии)",
      Allergen.sesame: "кунжут",
    },
    diets: {
      FoodFilter.vegan: "Я не ем никаких продуктов животного происхождения: ни мяса, ни рыбы, ни молочных продуктов, ни яиц, ни мёда.",
      FoodFilter.vegetarian: "Я не ем мясо и рыбу.",
      FoodFilter.halal: "Я ем только халяльную пищу.",
      FoodFilter.noPork: "Я не ем свинину и ничего, что приготовлено с ней, включая сало и желатин.",
      FoodFilter.noAlcohol: "Я не употребляю алкоголь, в том числе в блюдах.",
    },
  ),
  'ko': WaiterPhrases(
    title: "꼭 읽어 주세요: 제 음식 알레르기와 식단 제한",
    allergyIntro: "저는 심한 음식 알레르기가 있습니다. 다음은 절대 먹을 수 없습니다:",
    allergyOutro: "숨은 재료, 공용 조리 기름, 공용 조리대를 포함해 제 음식에 위 재료가 전혀 들어가지 않도록 확인해 주세요.",
    dietIntro: "저는 다음 식단 규칙도 지킵니다:",
    thanks: "도와주셔서 정말 감사합니다!",
    allergens: {
      Allergen.peanuts: "땅콩",
      Allergen.treeNuts: "견과류(아몬드, 헤이즐넛, 호두, 캐슈넛, 피스타치오)",
      Allergen.milk: "우유 및 유제품",
      Allergen.eggs: "달걀",
      Allergen.gluten: "글루텐(밀, 보리, 호밀)",
      Allergen.soy: "대두",
      Allergen.fish: "생선",
      Allergen.shellfish: "갑각류·조개류(새우, 게, 바닷가재, 홍합)",
      Allergen.sesame: "참깨",
    },
    diets: {
      FoodFilter.vegan: "저는 모든 동물성 식품을 먹지 않습니다. 고기, 생선, 유제품, 달걀, 꿀도 먹지 않습니다.",
      FoodFilter.vegetarian: "저는 고기와 생선을 먹지 않습니다.",
      FoodFilter.halal: "저는 할랄 음식만 먹습니다.",
      FoodFilter.noPork: "저는 돼지고기와 돼지고기가 들어간 모든 음식을 먹지 않습니다. 라드와 젤라틴도 포함됩니다.",
      FoodFilter.noAlcohol: "저는 요리에 들어가는 것을 포함해 알코올을 섭취하지 않습니다.",
    },
  ),
  'ja': WaiterPhrases(
    title: "お読みください：私の食物アレルギーと食事の制限",
    allergyIntro: "私は重い食物アレルギーがあります。次のものは食べられません：",
    allergyOutro: "隠れた原材料、共用の調理油、共用の調理台も含め、私の料理にこれらが一切入っていないことを確認してください。",
    dietIntro: "次の食事ルールも守っています：",
    thanks: "ご協力ありがとうございます！",
    allergens: {
      Allergen.peanuts: "ピーナッツ",
      Allergen.treeNuts: "ナッツ類（アーモンド、ヘーゼルナッツ、くるみ、カシューナッツ、ピスタチオ）",
      Allergen.milk: "牛乳・乳製品",
      Allergen.eggs: "卵",
      Allergen.gluten: "グルテン（小麦、大麦、ライ麦）",
      Allergen.soy: "大豆",
      Allergen.fish: "魚",
      Allergen.shellfish: "甲殻類・貝類（エビ、カニ、ロブスター、ムール貝）",
      Allergen.sesame: "ごま",
    },
    diets: {
      FoodFilter.vegan: "動物性食品は一切食べません。肉、魚、乳製品、卵、はちみつも含みません。",
      FoodFilter.vegetarian: "肉と魚は食べません。",
      FoodFilter.halal: "ハラール食品のみを食べます。",
      FoodFilter.noPork: "豚肉と、ラードやゼラチンを含む豚由来のものは一切食べません。",
      FoodFilter.noAlcohol: "料理に使われるものも含め、アルコールは摂取しません。",
    },
  ),
  'pt': WaiterPhrases(
    title: "Por favor, leia: minhas alergias alimentares e minha dieta",
    allergyIntro: "Tenho uma alergia alimentar grave. Não posso comer:",
    allergyOutro: "Por favor, garanta que minha refeição não contenha nada disso, incluindo ingredientes ocultos, óleo de cozinha compartilhado ou superfícies compartilhadas.",
    dietIntro: "Também sigo estas regras alimentares:",
    thanks: "Muito obrigado pela ajuda!",
    allergens: {
      Allergen.peanuts: "amendoim",
      Allergen.treeNuts: "castanhas e nozes (amêndoas, avelãs, nozes, castanha-de-caju, pistache)",
      Allergen.milk: "leite e laticínios",
      Allergen.eggs: "ovos",
      Allergen.gluten: "glúten (trigo, cevada, centeio)",
      Allergen.soy: "soja",
      Allergen.fish: "peixe",
      Allergen.shellfish: "frutos do mar com casca (camarão, caranguejo, lagosta, mexilhão)",
      Allergen.sesame: "gergelim",
    },
    diets: {
      FoodFilter.vegan: "Não como nenhum produto de origem animal: nada de carne, peixe, laticínios, ovos ou mel.",
      FoodFilter.vegetarian: "Não como carne nem peixe.",
      FoodFilter.halal: "Como apenas comida halal.",
      FoodFilter.noPork: "Não como carne de porco nem nada feito com ela, incluindo banha e gelatina.",
      FoodFilter.noAlcohol: "Não consumo álcool, nem mesmo no preparo dos alimentos.",
    },
  ),
  'nl': WaiterPhrases(
    title: "Lees dit alstublieft: mijn voedselallergieën en dieet",
    allergyIntro: "Ik heb een ernstige voedselallergie. Ik mag niet eten:",
    allergyOutro: "Zorg er alstublieft voor dat mijn maaltijd niets hiervan bevat, ook geen verborgen ingrediënten, gedeelde bakolie of gedeelde werkvlakken.",
    dietIntro: "Ik volg ook deze eetregels:",
    thanks: "Hartelijk dank voor uw hulp!",
    allergens: {
      Allergen.peanuts: "pinda's",
      Allergen.treeNuts: "noten (amandelen, hazelnoten, walnoten, cashewnoten, pistachenoten)",
      Allergen.milk: "melk en zuivelproducten",
      Allergen.eggs: "eieren",
      Allergen.gluten: "gluten (tarwe, gerst, rogge)",
      Allergen.soy: "soja",
      Allergen.fish: "vis",
      Allergen.shellfish: "schaal- en schelpdieren (garnalen, krab, kreeft, mosselen)",
      Allergen.sesame: "sesam",
    },
    diets: {
      FoodFilter.vegan: "Ik eet geen dierlijke producten: geen vlees, vis, zuivel, eieren of honing.",
      FoodFilter.vegetarian: "Ik eet geen vlees en geen vis.",
      FoodFilter.halal: "Ik eet alleen halalvoedsel.",
      FoodFilter.noPork: "Ik eet geen varkensvlees of iets dat ermee is gemaakt, ook geen reuzel of gelatine.",
      FoodFilter.noAlcohol: "Ik gebruik geen alcohol, ook niet bij het koken.",
    },
  ),
};
