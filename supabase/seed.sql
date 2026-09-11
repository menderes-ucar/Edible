insert into public.countries (id, iso2, default_name) values
  ('10000000-0000-0000-0000-000000000001', 'TR', 'Türkiye'),
  ('10000000-0000-0000-0000-000000000002', 'JP', 'Japan'),
  ('10000000-0000-0000-0000-000000000003', 'IT', 'Italy')
on conflict (id) do nothing;

insert into public.country_translations (country_id, language_code, name) values
  ('10000000-0000-0000-0000-000000000001', 'en', 'Türkiye'),
  ('10000000-0000-0000-0000-000000000001', 'tr', 'Türkiye'),
  ('10000000-0000-0000-0000-000000000002', 'en', 'Japan'),
  ('10000000-0000-0000-0000-000000000002', 'tr', 'Japonya'),
  ('10000000-0000-0000-0000-000000000003', 'en', 'Italy'),
  ('10000000-0000-0000-0000-000000000003', 'tr', 'İtalya')
on conflict (country_id, language_code) do update
set name = excluded.name;

insert into public.cities (id, country_id, default_name, latitude, longitude) values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Istanbul', 41.0082, 28.9784),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'Tokyo', 35.6762, 139.6503),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'Rome', 41.9028, 12.4964)
on conflict (id) do nothing;

insert into public.city_translations (city_id, language_code, name) values
  ('20000000-0000-0000-0000-000000000001', 'en', 'Istanbul'),
  ('20000000-0000-0000-0000-000000000001', 'tr', 'İstanbul'),
  ('20000000-0000-0000-0000-000000000002', 'en', 'Tokyo'),
  ('20000000-0000-0000-0000-000000000002', 'tr', 'Tokyo'),
  ('20000000-0000-0000-0000-000000000003', 'en', 'Rome'),
  ('20000000-0000-0000-0000-000000000003', 'tr', 'Roma')
on conflict (city_id, language_code) do update
set name = excluded.name;

insert into public.contents (
  id, city_id, category_id, latitude, longitude, is_featured, status
) values
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'place', 41.0054, 28.9768, true, 'published'),
  ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', 'snack', 41.0369, 28.9850, false, 'published'),
  ('30000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002', 'place', 35.7148, 139.7967, true, 'published'),
  ('30000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000002', 'food', 35.6938, 139.7034, false, 'published'),
  ('30000000-0000-0000-0000-000000000005', '20000000-0000-0000-0000-000000000003', 'place', 41.8902, 12.4922, true, 'published'),
  ('30000000-0000-0000-0000-000000000006', '20000000-0000-0000-0000-000000000003', 'drink', 41.9028, 12.4964, false, 'published')
on conflict (id) do nothing;

insert into public.content_translations (
  content_id, language_code, title, short_description, description, tags
) values
  (
    '30000000-0000-0000-0000-000000000001', 'en',
    'Sultanahmet Square',
    'The heart of Istanbul’s historic peninsula.',
    'A historic district within walking distance of Hagia Sophia, the Blue Mosque and Basilica Cistern.',
    array['history','architecture','walking']
  ),
  (
    '30000000-0000-0000-0000-000000000001', 'tr',
    'Sultanahmet Meydanı',
    'İstanbul’un tarihi yarımadasının kalbi.',
    'Ayasofya, Sultanahmet Camii ve Yerebatan Sarnıcı gibi önemli noktalara yürüyerek ulaşabileceğin tarihi bölge.',
    array['tarih','mimari','yürüyüş']
  ),
  (
    '30000000-0000-0000-0000-000000000002', 'en',
    'Simit',
    'A sesame-covered crunchy street-food classic.',
    'Simit is commonly eaten for breakfast or during the day with tea and is easy to find at bakeries and street carts.',
    array['street food','breakfast','budget']
  ),
  (
    '30000000-0000-0000-0000-000000000002', 'tr',
    'Simit',
    'Susamlı, çıtır ve şehirle özdeşleşmiş sokak lezzeti.',
    'Simit kahvaltıda veya gün içinde çayla birlikte sıkça tüketilir. Sokak arabalarında ve fırınlarda kolayca bulunur.',
    array['sokak lezzeti','kahvaltı','uygun fiyat']
  ),
  (
    '30000000-0000-0000-0000-000000000003', 'en',
    'Sensō-ji',
    'Historic Buddhist temple in Asakusa.',
    'One of Tokyo’s best-known historic landmarks, commonly explored together with Nakamise shopping street.',
    array['temple','history']
  ),
  (
    '30000000-0000-0000-0000-000000000003', 'tr',
    'Sensō-ji',
    'Asakusa’daki tarihi Budist tapınağı.',
    'Tokyo’nun en bilinen tarihi noktalarından biri. Nakamise alışveriş sokağıyla birlikte gezilebilir.',
    array['tapınak','tarih']
  ),
  (
    '30000000-0000-0000-0000-000000000004', 'en',
    'Ramen',
    'A Japanese staple with many broth and noodle styles.',
    'Tokyo offers many ramen styles including shoyu, miso and tonkotsu, often served in small specialist shops.',
    array['noodles','hot meal']
  ),
  (
    '30000000-0000-0000-0000-000000000004', 'tr',
    'Ramen',
    'Farklı et suyu ve noodle stilleriyle Japon mutfağının vazgeçilmezi.',
    'Tokyo’da shoyu, miso, tonkotsu gibi birçok ramen çeşidi bulabilirsin. Küçük ramen dükkânları seyahat deneyiminin önemli bir parçasıdır.',
    array['noodle','sıcak yemek']
  ),
  (
    '30000000-0000-0000-0000-000000000005', 'en',
    'Colosseum',
    'The iconic amphitheatre of ancient Rome.',
    'One of Rome’s most recognizable historic landmarks and a central stop on an ancient-city itinerary.',
    array['ancient Rome','history']
  ),
  (
    '30000000-0000-0000-0000-000000000005', 'tr',
    'Kolezyum',
    'Antik Roma’nın simgesel amfitiyatrosu.',
    'Roma’nın en tanınan tarihi yapılarından biri ve antik şehir rotasının merkez noktalarından.',
    array['antik roma','tarih']
  ),
  (
    '30000000-0000-0000-0000-000000000006', 'en',
    'Espresso',
    'At the center of everyday Italian coffee culture.',
    'Espresso is often enjoyed quickly while standing at the bar, a small but memorable part of daily Italian life.',
    array['coffee','culture']
  ),
  (
    '30000000-0000-0000-0000-000000000006', 'tr',
    'Espresso',
    'İtalya’daki günlük kahve kültürünün merkezinde.',
    'Espresso çoğu zaman bar tezgâhında hızlıca içilir. Kahve sipariş alışkanlıkları İtalyan günlük yaşamının güzel bir parçasıdır.',
    array['kahve','kültür']
  )
on conflict (content_id, language_code) do update set
  title = excluded.title,
  short_description = excluded.short_description,
  description = excluded.description,
  tags = excluded.tags;
