-- Edible Phase 22.5: production-like development/test dataset.

-- 150 Explore contents: 50 Istanbul, 50 Tokyo, 50 Rome.

-- TEST/editorial seed only; not a source for live opening hours or live prices.



alter table public.categories add column if not exists sort_order integer not null default 0;

alter table public.categories add column if not exists sort_order integer not null default 0;
alter table public.categories add column if not exists slug text;
insert into public.categories (key, slug, sort_order) values
('place','place',10),('food','food',20),('snack','snack',30),('culture','culture',40),('fruit','fruit',50),('drink','drink',60)
on conflict (key) do update set slug=excluded.slug, sort_order=excluded.sort_order;

insert into public.countries (code,default_name) values ('TR','Türkiye') on conflict (code) do update set default_name=excluded.default_name;

insert into public.countries (code,default_name) values ('JP','Japan') on conflict (code) do update set default_name=excluded.default_name;

insert into public.countries (code,default_name) values ('IT','Italy') on conflict (code) do update set default_name=excluded.default_name;

insert into public.country_translations (country_id,locale,display_name) select id,'en','Türkiye' from public.countries where code='TR' on conflict (country_id,locale) do update set display_name=excluded.display_name;

insert into public.country_translations (country_id,locale,display_name) select id,'tr','Türkiye' from public.countries where code='TR' on conflict (country_id,locale) do update set display_name=excluded.display_name;

insert into public.country_translations (country_id,locale,display_name) select id,'en','Japan' from public.countries where code='JP' on conflict (country_id,locale) do update set display_name=excluded.display_name;

insert into public.country_translations (country_id,locale,display_name) select id,'tr','Japonya' from public.countries where code='JP' on conflict (country_id,locale) do update set display_name=excluded.display_name;

insert into public.country_translations (country_id,locale,display_name) select id,'en','Italy' from public.countries where code='IT' on conflict (country_id,locale) do update set display_name=excluded.display_name;

insert into public.country_translations (country_id,locale,display_name) select id,'tr','İtalya' from public.countries where code='IT' on conflict (country_id,locale) do update set display_name=excluded.display_name;

insert into public.cities (country_id,default_name,latitude,longitude)
select co.id,'Istanbul',41.0082,28.9784 from public.countries co
where co.code='TR' and not exists (
  select 1 from public.cities ci where ci.country_id=co.id and lower(ci.default_name)=lower('Istanbul')
);

insert into public.city_translations (city_id,locale,display_name)
select ci.id,'en','Istanbul' from public.cities ci join public.countries co on co.id=ci.country_id
where co.code='TR' and lower(ci.default_name)=lower('Istanbul')
order by ci.created_at asc limit 1
on conflict (city_id,locale) do update set display_name=excluded.display_name;

insert into public.city_translations (city_id,locale,display_name)
select ci.id,'tr','İstanbul' from public.cities ci join public.countries co on co.id=ci.country_id
where co.code='TR' and lower(ci.default_name)=lower('Istanbul')
order by ci.created_at asc limit 1
on conflict (city_id,locale) do update set display_name=excluded.display_name;

insert into public.cities (country_id,default_name,latitude,longitude)
select co.id,'Tokyo',35.6762,139.6503 from public.countries co
where co.code='JP' and not exists (
  select 1 from public.cities ci where ci.country_id=co.id and lower(ci.default_name)=lower('Tokyo')
);

insert into public.city_translations (city_id,locale,display_name)
select ci.id,'en','Tokyo' from public.cities ci join public.countries co on co.id=ci.country_id
where co.code='JP' and lower(ci.default_name)=lower('Tokyo')
order by ci.created_at asc limit 1
on conflict (city_id,locale) do update set display_name=excluded.display_name;

insert into public.city_translations (city_id,locale,display_name)
select ci.id,'tr','Tokyo' from public.cities ci join public.countries co on co.id=ci.country_id
where co.code='JP' and lower(ci.default_name)=lower('Tokyo')
order by ci.created_at asc limit 1
on conflict (city_id,locale) do update set display_name=excluded.display_name;

insert into public.cities (country_id,default_name,latitude,longitude)
select co.id,'Rome',41.9028,12.4964 from public.countries co
where co.code='IT' and not exists (
  select 1 from public.cities ci where ci.country_id=co.id and lower(ci.default_name)=lower('Rome')
);

insert into public.city_translations (city_id,locale,display_name)
select ci.id,'en','Rome' from public.cities ci join public.countries co on co.id=ci.country_id
where co.code='IT' and lower(ci.default_name)=lower('Rome')
order by ci.created_at asc limit 1
on conflict (city_id,locale) do update set display_name=excluded.display_name;

insert into public.city_translations (city_id,locale,display_name)
select ci.id,'tr','Roma' from public.cities ci join public.countries co on co.id=ci.country_id
where co.code='IT' and lower(ci.default_name)=lower('Rome')
order by ci.created_at asc limit 1
on conflict (city_id,locale) do update set display_name=excluded.display_name;

update public.contents set status='archived',updated_at=now()
where id in (
'30000000-0000-0000-0000-000000000001'::uuid,'30000000-0000-0000-0000-000000000002'::uuid,
'30000000-0000-0000-0000-000000000003'::uuid,'30000000-0000-0000-0000-000000000004'::uuid,
'30000000-0000-0000-0000-000000000005'::uuid,'30000000-0000-0000-0000-000000000006'::uuid
);

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000001'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0086,28.9802,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000001'::uuid,'en','en','Hagia Sophia','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000001'::uuid,'tr','tr','Ayasofya','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000002'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0054,28.9768,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000002'::uuid,'en','en','Blue Mosque','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000002'::uuid,'tr','tr','Sultanahmet Camii','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000003'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0084,28.9779,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000003'::uuid,'en','en','Basilica Cistern','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000003'::uuid,'tr','tr','Yerebatan Sarnıcı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000004'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0115,28.9834,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000004'::uuid,'en','en','Topkapı Palace','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000004'::uuid,'tr','tr','Topkapı Sarayı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000005'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0107,28.9681,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000005'::uuid,'en','en','Grand Bazaar','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000005'::uuid,'tr','tr','Kapalıçarşı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000006'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0256,28.9741,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000006'::uuid,'en','en','Galata Tower','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000006'::uuid,'tr','tr','Galata Kulesi','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000007'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0392,29.0005,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000007'::uuid,'en','en','Dolmabahçe Palace','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000007'::uuid,'tr','tr','Dolmabahçe Sarayı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000008'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0471,29.0268,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000008'::uuid,'en','en','Ortaköy Mosque','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000008'::uuid,'tr','tr','Ortaköy Camii','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000009'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0162,28.9639,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000009'::uuid,'en','en','Süleymaniye Mosque','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000009'::uuid,'tr','tr','Süleymaniye Camii','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000010'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0294,28.9493,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000010'::uuid,'en','en','Balat Streets','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000010'::uuid,'tr','tr','Balat Sokakları','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000011'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),40.9905,29.0277,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000011'::uuid,'en','en','Kadıköy Market','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000011'::uuid,'tr','tr','Kadıköy Çarşısı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000012'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0538,28.9339,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000012'::uuid,'en','en','Pierre Loti Hill','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000012'::uuid,'tr','tr','Pierre Loti Tepesi','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000013'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0848,29.0567,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000013'::uuid,'en','en','Rumeli Fortress','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000013'::uuid,'tr','tr','Rumeli Hisarı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000014'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.0211,29.0041,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000014'::uuid,'en','en','Maiden''s Tower Viewpoint','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000014'::uuid,'tr','tr','Kız Kulesi Manzarası','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000015'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.034,28.9785,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000015'::uuid,'en','en','İstiklal Avenue','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000015'::uuid,'tr','tr','İstiklal Caddesi','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000016'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.0063,28.9763,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000016'::uuid,'en','en','Döner Kebab','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000016'::uuid,'tr','tr','Döner Kebap','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000017'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.025,28.9723,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000017'::uuid,'en','en','İskender Kebab','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000017'::uuid,'tr','tr','İskender Kebap','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000018'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.0377,28.9833,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000018'::uuid,'en','en','Grilled Köfte','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000018'::uuid,'tr','tr','Izgara Köfte','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000019'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),40.9883,29.028,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000019'::uuid,'en','en','Lahmacun','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000019'::uuid,'tr','tr','Lahmacun','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000020'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.047,29.027,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000020'::uuid,'en','en','Pide','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000020'::uuid,'tr','tr','Pide','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000021'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.0177,28.964,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000021'::uuid,'en','en','Mantı','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000021'::uuid,'tr','tr','Mantı','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000022'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.0063,28.9797,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000022'::uuid,'en','en','Kuru Fasulye','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000022'::uuid,'tr','tr','Kuru Fasulye','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000023'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.025,28.9757,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000023'::uuid,'en','en','Balık Ekmek','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000023'::uuid,'tr','tr','Balık Ekmek','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000024'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.0377,28.9867,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000024'::uuid,'en','en','Kokoreç','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000024'::uuid,'tr','tr','Kokoreç','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000025'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),40.9883,29.0263,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000025'::uuid,'en','en','Menemen','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000025'::uuid,'tr','tr','Menemen','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000026'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.047,29.0253,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000026'::uuid,'en','en','Su Böreği','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000026'::uuid,'tr','tr','Su Böreği','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000027'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.0177,28.9623,'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000027'::uuid,'en','en','Hünkar Beğendi','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000027'::uuid,'tr','tr','Hünkar Beğendi','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000028'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.0063,28.9763,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000028'::uuid,'en','en','Simit','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000028'::uuid,'tr','tr','Simit','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000029'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.025,28.9723,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000029'::uuid,'en','en','Baklava','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000029'::uuid,'tr','tr','Baklava','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000030'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.0377,28.9833,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000030'::uuid,'en','en','Turkish Delight','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000030'::uuid,'tr','tr','Lokum','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000031'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),40.9883,29.028,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000031'::uuid,'en','en','Roasted Chestnuts','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000031'::uuid,'tr','tr','Kestane Kebabı','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000032'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.047,29.027,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000032'::uuid,'en','en','Kumpir','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000032'::uuid,'tr','tr','Kumpir','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000033'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.0177,28.964,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000033'::uuid,'en','en','Stuffed Mussels','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000033'::uuid,'tr','tr','Midye Dolma','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000034'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.0063,28.9763,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000034'::uuid,'en','en','Turkish Bath Experience','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000034'::uuid,'tr','tr','Türk Hamamı Deneyimi','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000035'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.025,28.9723,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000035'::uuid,'en','en','Tea House Culture','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000035'::uuid,'tr','tr','Çay Evi Kültürü','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000036'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.0377,28.9833,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000036'::uuid,'en','en','Turkish Coffee Fortune Tradition','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000036'::uuid,'tr','tr','Türk Kahvesi Fal Geleneği','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000037'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),40.9883,29.028,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000037'::uuid,'en','en','Bosphorus Ferry Ritual','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000037'::uuid,'tr','tr','Boğaz Vapuru Ritüeli','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000038'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.047,29.027,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000038'::uuid,'en','en','Meyhane Table Culture','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000038'::uuid,'tr','tr','Meyhane Sofrası Kültürü','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000039'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.0177,28.964,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000039'::uuid,'en','en','Long Weekend Breakfast','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000039'::uuid,'tr','tr','Uzun Hafta Sonu Kahvaltısı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000040'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.0063,28.9797,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000040'::uuid,'en','en','Mosque Visit Etiquette','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000040'::uuid,'tr','tr','Cami Ziyaret Adabı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000041'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.0063,28.9763,'https://images.unsplash.com/photo-1511081692775-05d0f180a065?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000041'::uuid,'en','en','Turkish Tea','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000041'::uuid,'tr','tr','Türk Çayı','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000042'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.025,28.9723,'https://images.unsplash.com/photo-1511081692775-05d0f180a065?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000042'::uuid,'en','en','Turkish Coffee','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000042'::uuid,'tr','tr','Türk Kahvesi','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000043'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.0377,28.9833,'https://images.unsplash.com/photo-1511081692775-05d0f180a065?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000043'::uuid,'en','en','Ayran','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000043'::uuid,'tr','tr','Ayran','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000044'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),40.9883,29.028,'https://images.unsplash.com/photo-1511081692775-05d0f180a065?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000044'::uuid,'en','en','Boza','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000044'::uuid,'tr','tr','Boza','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000045'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.047,29.027,'https://images.unsplash.com/photo-1511081692775-05d0f180a065?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000045'::uuid,'en','en','Şalgam','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000045'::uuid,'tr','tr','Şalgam','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000046'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.0063,28.9763,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000046'::uuid,'en','en','Fresh Figs','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000046'::uuid,'tr','tr','Taze İncir','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000047'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.025,28.9723,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000047'::uuid,'en','en','Pomegranate','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000047'::uuid,'tr','tr','Nar','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000048'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.0377,28.9833,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000048'::uuid,'en','en','Cherries','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000048'::uuid,'tr','tr','Kiraz','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000049'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),40.9883,29.028,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000049'::uuid,'en','en','Mulberries','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000049'::uuid,'tr','tr','Dut','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('31000000-0000-0000-0000-000000000050'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.047,29.027,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000050'::uuid,'en','en','Melon','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','istanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('31000000-0000-0000-0000-000000000050'::uuid,'tr','tr','Kavun','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','i̇stanbul','tr'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000001'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.7148,139.7967,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000001'::uuid,'en','en','Sensō-ji','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000001'::uuid,'tr','tr','Sensō-ji','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000002'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6764,139.6993,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000002'::uuid,'en','en','Meiji Shrine','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000002'::uuid,'tr','tr','Meiji Tapınağı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000003'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6595,139.7005,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000003'::uuid,'en','en','Shibuya Crossing','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000003'::uuid,'tr','tr','Shibuya Kavşağı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000004'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.7101,139.8107,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000004'::uuid,'en','en','Tokyo Skytree','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000004'::uuid,'tr','tr','Tokyo Skytree','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000005'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6586,139.7454,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000005'::uuid,'en','en','Tokyo Tower','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000005'::uuid,'tr','tr','Tokyo Tower','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000006'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6852,139.7528,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000006'::uuid,'en','en','Imperial Palace East Gardens','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000006'::uuid,'tr','tr','İmparatorluk Sarayı Doğu Bahçeleri','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000007'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.7148,139.773,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000007'::uuid,'en','en','Ueno Park','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000007'::uuid,'tr','tr','Ueno Parkı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000008'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6654,139.7707,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000008'::uuid,'en','en','Tsukiji Outer Market','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000008'::uuid,'tr','tr','Tsukiji Dış Pazarı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000009'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6491,139.7898,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000009'::uuid,'en','en','teamLab Planets Area','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000009'::uuid,'tr','tr','teamLab Planets Bölgesi','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000010'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6272,139.7768,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000010'::uuid,'en','en','Odaiba Seaside','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000010'::uuid,'tr','tr','Odaiba Sahili','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000011'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.7274,139.7658,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000011'::uuid,'en','en','Yanaka Ginza','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000011'::uuid,'tr','tr','Yanaka Ginza','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000012'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6852,139.71,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000012'::uuid,'en','en','Shinjuku Gyoen','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000012'::uuid,'tr','tr','Shinjuku Gyoen','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000013'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6597,139.7635,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000013'::uuid,'en','en','Hamarikyu Gardens','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000013'::uuid,'tr','tr','Hamarikyu Bahçeleri','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000014'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6984,139.7731,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000014'::uuid,'en','en','Akihabara Electric Town','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000014'::uuid,'tr','tr','Akihabara Elektronik Bölgesi','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000015'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),35.6716,139.7043,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000015'::uuid,'en','en','Harajuku Takeshita Street','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000015'::uuid,'tr','tr','Harajuku Takeshita Sokağı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000016'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.7123,139.7953,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000016'::uuid,'en','en','Tokyo Ramen','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000016'::uuid,'tr','tr','Tokyo Ramen','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000017'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.659,139.6993,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000017'::uuid,'en','en','Edomae Sushi','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000017'::uuid,'tr','tr','Edomae Sushi','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000018'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.6947,139.7013,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000018'::uuid,'en','en','Tempura','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000018'::uuid,'tr','tr','Tempura','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000019'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.6693,139.704,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000019'::uuid,'en','en','Soba','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000019'::uuid,'tr','tr','Soba','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000020'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.665,139.771,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000020'::uuid,'en','en','Udon','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000020'::uuid,'tr','tr','Udon','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000021'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.6997,139.773,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000021'::uuid,'en','en','Tonkatsu','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000021'::uuid,'tr','tr','Tonkatsu','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000022'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.7123,139.7987,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000022'::uuid,'en','en','Yakitori','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000022'::uuid,'tr','tr','Yakitori','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000023'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.659,139.7027,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000023'::uuid,'en','en','Okonomiyaki','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000023'::uuid,'tr','tr','Okonomiyaki','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000024'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.6947,139.7047,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000024'::uuid,'en','en','Monjayaki','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000024'::uuid,'tr','tr','Monjayaki','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000025'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.6693,139.7023,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000025'::uuid,'en','en','Japanese Curry Rice','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000025'::uuid,'tr','tr','Japon Köri Pilavı','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000026'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.665,139.7693,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000026'::uuid,'en','en','Gyūdon','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000026'::uuid,'tr','tr','Gyūdon','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000027'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),35.6997,139.7713,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000027'::uuid,'en','en','Unagi','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000027'::uuid,'tr','tr','Unagi','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000028'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),35.7123,139.7953,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000028'::uuid,'en','en','Melon Pan','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000028'::uuid,'tr','tr','Melon Pan','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000029'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),35.659,139.6993,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000029'::uuid,'en','en','Taiyaki','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000029'::uuid,'tr','tr','Taiyaki','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000030'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),35.6947,139.7013,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000030'::uuid,'en','en','Dorayaki','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000030'::uuid,'tr','tr','Dorayaki','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000031'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),35.6693,139.704,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000031'::uuid,'en','en','Senbei','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000031'::uuid,'tr','tr','Senbei','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000032'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),35.665,139.771,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000032'::uuid,'en','en','Onigiri','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000032'::uuid,'tr','tr','Onigiri','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000033'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),35.6997,139.773,'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000033'::uuid,'en','en','Mochi','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000033'::uuid,'tr','tr','Mochi','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000034'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),35.7123,139.7953,'https://images.unsplash.com/photo-1542051841857-5f90071e7989?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000034'::uuid,'en','en','Izakaya Evening','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000034'::uuid,'tr','tr','Izakaya Akşamı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000035'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),35.659,139.6993,'https://images.unsplash.com/photo-1542051841857-5f90071e7989?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000035'::uuid,'en','en','Konbini Culture','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000035'::uuid,'tr','tr','Konbini Kültürü','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000036'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),35.6947,139.7013,'https://images.unsplash.com/photo-1542051841857-5f90071e7989?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000036'::uuid,'en','en','Sentō Bath Culture','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000036'::uuid,'tr','tr','Sentō Hamam Kültürü','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000037'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),35.6693,139.704,'https://images.unsplash.com/photo-1542051841857-5f90071e7989?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000037'::uuid,'en','en','Shrine Visit Etiquette','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000037'::uuid,'tr','tr','Şinto Tapınağı Ziyaret Adabı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000038'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),35.665,139.771,'https://images.unsplash.com/photo-1542051841857-5f90071e7989?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000038'::uuid,'en','en','Train Queue Etiquette','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000038'::uuid,'tr','tr','Tren Sıra Adabı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000039'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),35.6997,139.773,'https://images.unsplash.com/photo-1542051841857-5f90071e7989?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000039'::uuid,'en','en','Depachika Food Hall','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000039'::uuid,'tr','tr','Depachika Yemek Katı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000040'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),35.7123,139.7987,'https://images.unsplash.com/photo-1542051841857-5f90071e7989?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000040'::uuid,'en','en','Karaoke Night','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000040'::uuid,'tr','tr','Karaoke Gecesi','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000041'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),35.7123,139.7953,'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000041'::uuid,'en','en','Matcha','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000041'::uuid,'tr','tr','Matcha','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000042'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),35.659,139.6993,'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000042'::uuid,'en','en','Canned Coffee','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000042'::uuid,'tr','tr','Kutulu Kahve','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000043'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),35.6947,139.7013,'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000043'::uuid,'en','en','Mugicha','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000043'::uuid,'tr','tr','Mugicha','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000044'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),35.6693,139.704,'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000044'::uuid,'en','en','Ramune','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000044'::uuid,'tr','tr','Ramune','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000045'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),35.665,139.771,'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000045'::uuid,'en','en','Calpis','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000045'::uuid,'tr','tr','Calpis','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000046'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),35.7123,139.7953,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000046'::uuid,'en','en','Mikan','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000046'::uuid,'tr','tr','Mikan','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000047'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),35.659,139.6993,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000047'::uuid,'en','en','Nashi Pear','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000047'::uuid,'tr','tr','Nashi Armudu','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000048'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),35.6947,139.7013,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000048'::uuid,'en','en','Japanese Strawberries','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000048'::uuid,'tr','tr','Japon Çileği','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000049'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),35.6693,139.704,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000049'::uuid,'en','en','Musk Melon','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000049'::uuid,'tr','tr','Misk Kavunu','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('32000000-0000-0000-0000-000000000050'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),35.665,139.771,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000050'::uuid,'en','en','Persimmon','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('32000000-0000-0000-0000-000000000050'::uuid,'tr','tr','Trabzon Hurması','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','tokyo','jp'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000001'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.8902,12.4922,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000001'::uuid,'en','en','Colosseum','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000001'::uuid,'tr','tr','Kolezyum','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000002'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.8925,12.4853,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000002'::uuid,'en','en','Roman Forum','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000002'::uuid,'tr','tr','Roma Forumu','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000003'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.8986,12.4769,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000003'::uuid,'en','en','Pantheon','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000003'::uuid,'tr','tr','Pantheon','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000004'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.9009,12.4833,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000004'::uuid,'en','en','Trevi Fountain','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000004'::uuid,'tr','tr','Trevi Çeşmesi','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000005'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.9059,12.4823,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',true,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000005'::uuid,'en','en','Spanish Steps','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000005'::uuid,'tr','tr','İspanyol Merdivenleri','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000006'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.8992,12.4731,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000006'::uuid,'en','en','Piazza Navona','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000006'::uuid,'tr','tr','Piazza Navona','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000007'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.9065,12.4536,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000007'::uuid,'en','en','Vatican Museums','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000007'::uuid,'tr','tr','Vatikan Müzeleri','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000008'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.9022,12.4573,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000008'::uuid,'en','en','St. Peter''s Square','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000008'::uuid,'tr','tr','Aziz Petrus Meydanı','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000009'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.9031,12.4663,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000009'::uuid,'en','en','Castel Sant''Angelo','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000009'::uuid,'tr','tr','Castel Sant''Angelo','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000010'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.9142,12.4922,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000010'::uuid,'en','en','Villa Borghese','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000010'::uuid,'tr','tr','Villa Borghese','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000011'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.8897,12.4708,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000011'::uuid,'en','en','Trastevere','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000011'::uuid,'tr','tr','Trastevere','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000012'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.8957,12.4722,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000012'::uuid,'en','en','Campo de'' Fiori','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000012'::uuid,'tr','tr','Campo de'' Fiori','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000013'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.8931,12.4828,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000013'::uuid,'en','en','Capitoline Museums','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000013'::uuid,'tr','tr','Capitoline Müzeleri','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000014'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.879,12.4925,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 90, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000014'::uuid,'en','en','Baths of Caracalla','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000014'::uuid,'tr','tr','Caracalla Hamamları','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000015'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='place' limit 1),41.8429,12.5296,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Morning", "estimated_visit_minutes": 120, "local_tip": "Save this stop to a trip and combine nearby places to reduce backtracking."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000015'::uuid,'en','en','Appian Way','Landmark','A well-known stop that helps test map discovery, clustering and itinerary planning.',array['place','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000015'::uuid,'tr','tr','Appia Yolu','Önemli nokta','Harita keşfi, clustering ve seyahat planlama testleri için kullanılan bilinen bir durak.',array['place','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000016'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.8883,12.4903,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000016'::uuid,'en','en','Carbonara','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000016'::uuid,'tr','tr','Carbonara','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000017'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.899,12.4713,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000017'::uuid,'en','en','Cacio e Pepe','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000017'::uuid,'tr','tr','Cacio e Pepe','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000018'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.9047,12.4943,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000018'::uuid,'en','en','Amatriciana','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000018'::uuid,'tr','tr','Amatriciana','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000019'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.8873,12.471,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000019'::uuid,'en','en','Pasta alla Gricia','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000019'::uuid,'tr','tr','Pasta alla Gricia','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000020'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.906,12.482,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000020'::uuid,'en','en','Saltimbocca alla Romana','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000020'::uuid,'tr','tr','Saltimbocca alla Romana','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000021'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.8967,12.472,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000021'::uuid,'en','en','Coda alla Vaccinara','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000021'::uuid,'tr','tr','Coda alla Vaccinara','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000022'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.8883,12.4937,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000022'::uuid,'en','en','Trippa alla Romana','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000022'::uuid,'tr','tr','Trippa alla Romana','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000023'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.899,12.4747,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000023'::uuid,'en','en','Carciofi alla Giudia','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000023'::uuid,'tr','tr','Carciofi alla Giudia','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000024'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.9047,12.4977,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000024'::uuid,'en','en','Supplì','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000024'::uuid,'tr','tr','Supplì','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000025'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.8873,12.4693,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000025'::uuid,'en','en','Pizza al Taglio','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000025'::uuid,'tr','tr','Dilim Pizza','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000026'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.906,12.4803,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000026'::uuid,'en','en','Porchetta','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000026'::uuid,'tr','tr','Porchetta','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000027'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='food' limit 1),41.8967,12.4703,'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000027'::uuid,'en','en','Gnocchi alla Romana','Local dish','A representative local dish used to test food discovery, dietary filters and trip planning.',array['food','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000027'::uuid,'tr','tr','Gnocchi alla Romana','Yerel yemek','Yemek keşfi, beslenme filtreleri ve seyahat planlama testleri için kullanılan yerel bir yemek.',array['food','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000028'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.8883,12.4903,'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000028'::uuid,'en','en','Maritozzo','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000028'::uuid,'tr','tr','Maritozzo','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000029'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.899,12.4713,'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000029'::uuid,'en','en','Gelato','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000029'::uuid,'tr','tr','Gelato','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000030'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.9047,12.4943,'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000030'::uuid,'en','en','Trapizzino','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000030'::uuid,'tr','tr','Trapizzino','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000031'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.8873,12.471,'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000031'::uuid,'en','en','Crostata Ricotta e Visciole','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000031'::uuid,'tr','tr','Ricotta ve Vişneli Crostata','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000032'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.906,12.482,'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000032'::uuid,'en','en','Italian Biscotti','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000032'::uuid,'tr','tr','İtalyan Bisküvisi','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000033'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='snack' limit 1),41.8967,12.472,'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000033'::uuid,'en','en','Roasted Chestnuts','Local snack','A popular snack or quick bite used to test lightweight food discovery and price filters.',array['snack','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000033'::uuid,'tr','tr','Kavrulmuş Kestane','Yerel atıştırmalık','Hızlı yemek keşfi ve fiyat filtrelerini test etmek için kullanılan popüler bir atıştırmalık.',array['snack','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000034'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.8883,12.4903,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000034'::uuid,'en','en','Aperitivo Hour','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000034'::uuid,'tr','tr','Aperitivo Saati','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000035'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.899,12.4713,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000035'::uuid,'en','en','Espresso Bar Etiquette','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000035'::uuid,'tr','tr','Espresso Bar Adabı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000036'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.9047,12.4943,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000036'::uuid,'en','en','Evening Passeggiata','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000036'::uuid,'tr','tr','Akşam Passeggiata Geleneği','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000037'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.8873,12.471,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000037'::uuid,'en','en','Neighborhood Market Culture','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000037'::uuid,'tr','tr','Mahalle Pazarı Kültürü','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000038'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.906,12.482,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000038'::uuid,'en','en','Church Dress Etiquette','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000038'::uuid,'tr','tr','Kilise Giyim Adabı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000039'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.8967,12.472,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000039'::uuid,'en','en','Public Fountain Etiquette','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000039'::uuid,'tr','tr','Kamusal Çeşme Adabı','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000040'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='culture' limit 1),41.8883,12.4937,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1200&q=80',false,'published','{"best_time": "Late afternoon or evening", "estimated_visit_minutes": 60, "local_tip": "Observe local behavior first and follow posted guidance.", "etiquette": "Be respectful of local customs and shared spaces."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000040'::uuid,'en','en','Neighborhood Trattoria Culture','Local culture','A cultural experience used to test culture discovery, saved trips and itinerary variety.',array['culture','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000040'::uuid,'tr','tr','Mahalle Trattoria Kültürü','Yerel kültür','Kültür keşfi, kayıtlı seyahatler ve program çeşitliliğini test etmek için kullanılan bir deneyim.',array['culture','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000041'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.8883,12.4903,'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000041'::uuid,'en','en','Espresso','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000041'::uuid,'tr','tr','Espresso','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000042'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.899,12.4713,'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000042'::uuid,'en','en','Cappuccino','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000042'::uuid,'tr','tr','Cappuccino','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000043'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.9047,12.4943,'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000043'::uuid,'en','en','Chinotto','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000043'::uuid,'tr','tr','Chinotto','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000044'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.8873,12.471,'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000044'::uuid,'en','en','Sparkling Mineral Water','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000044'::uuid,'tr','tr','Gazlı Maden Suyu','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000045'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='drink' limit 1),41.906,12.482,'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Anytime", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000045'::uuid,'en','en','Local Table Wine','Local drink','A representative drink used to test drink discovery and food-intelligence filters.',array['drink','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000045'::uuid,'tr','tr','Yerel Sofra Şarabı','Yerel içecek','İçecek keşfi ve Food Intelligence filtrelerini test etmek için kullanılan yerel bir içecek.',array['drink','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000046'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.8883,12.4903,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000046'::uuid,'en','en','Blood Orange','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000046'::uuid,'tr','tr','Kan Portakalı','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000047'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.899,12.4713,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000047'::uuid,'en','en','Fresh Figs','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000047'::uuid,'tr','tr','Taze İncir','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000048'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.9047,12.4943,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 1, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000048'::uuid,'en','en','Table Grapes','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000048'::uuid,'tr','tr','Sofralık Üzüm','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000049'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.8873,12.471,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000049'::uuid,'en','en','Peaches','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000049'::uuid,'tr','tr','Şeftali','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.contents (id,city_id,category_id,latitude,longitude,cover_image_url,is_featured,status,metadata)
values ('33000000-0000-0000-0000-000000000050'::uuid,(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),(select id from public.categories where slug='fruit' limit 1),41.906,12.482,'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&w=1200&q=80',false,'published','{"price_level": 2, "best_time": "Lunch or afternoon", "local_tip": "Use Food Intelligence details before ordering if you have dietary requirements."}'::jsonb)
on conflict (id) do update set city_id=excluded.city_id,category_id=excluded.category_id,latitude=excluded.latitude,longitude=excluded.longitude,cover_image_url=excluded.cover_image_url,is_featured=excluded.is_featured,status='published',metadata=excluded.metadata,updated_at=now();

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000050'::uuid,'en','en','Strawberries','Seasonal produce','A fruit or produce experience used to test category filtering and local food exploration.',array['fruit','rome','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.content_translations (content_id,locale,language_code,title,short_description,description,tags)
values ('33000000-0000-0000-0000-000000000050'::uuid,'tr','tr','Çilek','Mevsimsel ürün','Kategori filtreleri ve yerel yemek keşfini test etmek için kullanılan meyve/ürün deneyimi.',array['fruit','roma','it'])
on conflict (content_id,language_code) do update set locale=excluded.locale,title=excluded.title,short_description=excluded.short_description,description=excluded.description,tags=excluded.tags;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000016'::uuid,'TRY',180,650,1,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000016'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000016'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000017'::uuid,'TRY',180,650,1,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000017'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000017'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000018'::uuid,'TRY',180,650,0,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000018'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000018'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000019'::uuid,'TRY',180,650,1,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000019'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000019'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000020'::uuid,'TRY',180,650,0,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000020'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000020'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000021'::uuid,'TRY',180,650,0,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000021'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000021'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000022'::uuid,'TRY',180,650,0,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000022'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000022'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000023'::uuid,'TRY',180,650,0,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000023'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000023'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000024'::uuid,'TRY',180,650,1,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000024'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000024'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000025'::uuid,'TRY',180,650,0,true,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000025'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000025'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000026'::uuid,'TRY',180,650,0,true,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000026'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000026'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000027'::uuid,'TRY',180,650,0,false,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000027'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000027'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000028'::uuid,'TRY',40,300,0,true,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000028'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000028'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000029'::uuid,'TRY',40,300,0,true,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000029'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000029'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000030'::uuid,'TRY',40,300,0,true,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000030'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000030'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000031'::uuid,'TRY',40,300,0,true,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000031'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000031'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000032'::uuid,'TRY',40,300,0,true,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000032'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000032'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000033'::uuid,'TRY',40,300,0,true,false,true,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000033'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000033'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000041'::uuid,'TRY',30,220,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000041'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000041'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000042'::uuid,'TRY',30,220,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000042'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000042'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000043'::uuid,'TRY',30,220,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000043'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000043'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000044'::uuid,'TRY',30,220,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000044'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000044'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000045'::uuid,'TRY',30,220,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000045'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000045'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000046'::uuid,'TRY',40,250,0,true,true,true,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000046'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000046'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000047'::uuid,'TRY',40,250,0,true,true,true,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000047'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000047'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000048'::uuid,'TRY',40,250,0,true,true,true,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000048'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000048'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000049'::uuid,'TRY',40,250,0,true,true,true,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000049'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000049'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('31000000-0000-0000-0000-000000000050'::uuid,'TRY',40,250,0,true,true,true,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000050'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('31000000-0000-0000-0000-000000000050'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000016'::uuid,'JPY',700,2600,1,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000016'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000016'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000017'::uuid,'JPY',700,2600,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000017'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000017'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000018'::uuid,'JPY',700,2600,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000018'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000018'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000019'::uuid,'JPY',700,2600,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000019'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000019'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000020'::uuid,'JPY',700,2600,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000020'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000020'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000021'::uuid,'JPY',700,2600,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000021'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000021'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000022'::uuid,'JPY',700,2600,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000022'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000022'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000023'::uuid,'JPY',700,2600,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000023'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000023'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000024'::uuid,'JPY',700,2600,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000024'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000024'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000025'::uuid,'JPY',700,2600,1,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000025'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000025'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000026'::uuid,'JPY',700,2600,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000026'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000026'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000027'::uuid,'JPY',700,2600,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000027'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000027'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000028'::uuid,'JPY',180,900,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000028'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000028'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000029'::uuid,'JPY',180,900,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000029'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000029'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000030'::uuid,'JPY',180,900,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000030'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000030'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000031'::uuid,'JPY',180,900,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000031'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000031'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000032'::uuid,'JPY',180,900,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000032'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000032'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000033'::uuid,'JPY',180,900,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000033'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000033'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000041'::uuid,'JPY',120,800,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000041'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000041'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000042'::uuid,'JPY',120,800,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000042'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000042'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000043'::uuid,'JPY',120,800,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000043'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000043'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000044'::uuid,'JPY',120,800,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000044'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000044'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000045'::uuid,'JPY',120,800,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000045'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000045'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000046'::uuid,'JPY',250,3000,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000046'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000046'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000047'::uuid,'JPY',250,3000,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000047'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000047'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000048'::uuid,'JPY',250,3000,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000048'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000048'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000049'::uuid,'JPY',250,3000,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000049'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000049'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('32000000-0000-0000-0000-000000000050'::uuid,'JPY',250,3000,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000050'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('32000000-0000-0000-0000-000000000050'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000016'::uuid,'EUR',7,28,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000016'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000016'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000017'::uuid,'EUR',7,28,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000017'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000017'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000018'::uuid,'EUR',7,28,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000018'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000018'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000019'::uuid,'EUR',7,28,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000019'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000019'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000020'::uuid,'EUR',7,28,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000020'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000020'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000021'::uuid,'EUR',7,28,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000021'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000021'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000022'::uuid,'EUR',7,28,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000022'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000022'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000023'::uuid,'EUR',7,28,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000023'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000023'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000024'::uuid,'EUR',7,28,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000024'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000024'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000025'::uuid,'EUR',7,28,0,false,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000025'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000025'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000026'::uuid,'EUR',7,28,0,false,false,false,true,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000026'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000026'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000027'::uuid,'EUR',7,28,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000027'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000027'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000028'::uuid,'EUR',2,9,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000028'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000028'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000029'::uuid,'EUR',2,9,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000029'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000029'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000030'::uuid,'EUR',2,9,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000030'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000030'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000031'::uuid,'EUR',2,9,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000031'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000031'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000032'::uuid,'EUR',2,9,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000032'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000032'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000033'::uuid,'EUR',2,9,0,true,false,false,false,false,false)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000033'::uuid,'en',array['local ingredients'],array['gluten'],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000033'::uuid,'tr',array['yerel malzemeler'],array['gluten'],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000041'::uuid,'EUR',1.5,9,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000041'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000041'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000042'::uuid,'EUR',1.5,9,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000042'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000042'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000043'::uuid,'EUR',1.5,9,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000043'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000043'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000044'::uuid,'EUR',1.5,9,0,true,false,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000044'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000044'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000045'::uuid,'EUR',1.5,9,0,true,false,false,false,true,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000045'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000045'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000046'::uuid,'EUR',2,8,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000046'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000046'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000047'::uuid,'EUR',2,8,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000047'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000047'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000048'::uuid,'EUR',2,8,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000048'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000048'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000049'::uuid,'EUR',2,8,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000049'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000049'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_details (content_id,currency_code,typical_price_min,typical_price_max,spicy_level,vegetarian,vegan,halal,contains_pork,contains_alcohol,gluten_free)
values ('33000000-0000-0000-0000-000000000050'::uuid,'EUR',2,8,0,true,true,false,false,false,true)
on conflict (content_id) do update set currency_code=excluded.currency_code,typical_price_min=excluded.typical_price_min,typical_price_max=excluded.typical_price_max,spicy_level=excluded.spicy_level,vegetarian=excluded.vegetarian,vegan=excluded.vegan,halal=excluded.halal,contains_pork=excluded.contains_pork,contains_alcohol=excluded.contains_alcohol,gluten_free=excluded.gluten_free,updated_at=now();

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000050'::uuid,'en',array['local ingredients'],'{}'::text[],'Typical single serving; portion size varies by vendor.','Enjoy it as locals commonly do; preparation varies by venue.','Anytime','Ask about ingredients and preparation if you have dietary restrictions.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.food_detail_translations (content_id,locale,ingredients,allergens,portion_info,how_locals_eat,when_locals_eat,before_you_order)
values ('33000000-0000-0000-0000-000000000050'::uuid,'tr',array['yerel malzemeler'],'{}'::text[],'Tipik tek porsiyon; porsiyon büyüklüğü satıcıya göre değişebilir.','Yerellerin yaygın tüketim biçimine göre dene; hazırlama şekli mekâna göre değişebilir.','Günün uygun saatlerinde.','Beslenme kısıtın varsa siparişten önce malzemeleri ve hazırlanışını sor.')
on conflict (content_id,locale) do update set ingredients=excluded.ingredients,allergens=excluded.allergens,portion_info=excluded.portion_info,how_locals_eat=excluded.how_locals_eat,when_locals_eat=excluded.when_locals_eat,before_you_order=excluded.before_you_order;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000001'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'doTip',10,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000001'::uuid,'41000000-0000-0000-0000-000000000001'::uuid,'en','en','Respect religious spaces','Dress modestly and follow posted guidance when visiting mosques.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000001'::uuid,'41000000-0000-0000-0000-000000000001'::uuid,'tr','tr','Respect religious spaces','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000002'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'dontTip',9,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000002'::uuid,'41000000-0000-0000-0000-000000000002'::uuid,'en','en','Do not block prayer areas','Avoid standing in active prayer rows or disturbing worshippers.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000002'::uuid,'41000000-0000-0000-0000-000000000002'::uuid,'tr','tr','Do not block prayer areas','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000003'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'tipping',8,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000003'::uuid,'41000000-0000-0000-0000-000000000003'::uuid,'en','en','Tipping','A small tip is appreciated in restaurants when service is good.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000003'::uuid,'41000000-0000-0000-0000-000000000003'::uuid,'tr','tr','Tipping','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000004'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'transport',8,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000004'::uuid,'41000000-0000-0000-0000-000000000004'::uuid,'en','en','Public transport','Offer priority seats and let passengers exit before boarding.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000004'::uuid,'41000000-0000-0000-0000-000000000004'::uuid,'tr','tr','Public transport','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000005'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'religiousPlace',9,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000005'::uuid,'41000000-0000-0000-0000-000000000005'::uuid,'en','en','Mosque visits','Remove shoes where required and keep voices low.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000005'::uuid,'41000000-0000-0000-0000-000000000005'::uuid,'tr','tr','Mosque visits','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000006'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'touristMistake',6,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000006'::uuid,'41000000-0000-0000-0000-000000000006'::uuid,'en','en','Rush-hour ferries','Allow extra time around commuter peaks and crowded piers.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000006'::uuid,'41000000-0000-0000-0000-000000000006'::uuid,'tr','tr','Rush-hour ferries','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000007'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'safety',10,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000007'::uuid,'41000000-0000-0000-0000-000000000007'::uuid,'en','en','Crowded areas','Keep valuables secure around busy transport hubs and tourist streets.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000007'::uuid,'41000000-0000-0000-0000-000000000007'::uuid,'tr','tr','Crowded areas','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000008'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'scam',10,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000008'::uuid,'41000000-0000-0000-0000-000000000008'::uuid,'en','en','Taxi pricing','Prefer licensed taxis and verify that the meter is running.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000008'::uuid,'41000000-0000-0000-0000-000000000008'::uuid,'tr','tr','Taxi pricing','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000009'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'scam',8,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000009'::uuid,'41000000-0000-0000-0000-000000000009'::uuid,'en','en','Unsolicited invitations','Be cautious with persistent invitations that quickly become expensive.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000009'::uuid,'41000000-0000-0000-0000-000000000009'::uuid,'tr','tr','Unsolicited invitations','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000010'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000010'::uuid,'41000000-0000-0000-0000-000000000010'::uuid,'en','en','Hello','A simple greeting works in most situations.','Merhaba','mehr-hah-bah','Hello')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000010'::uuid,'41000000-0000-0000-0000-000000000010'::uuid,'tr','tr','Hello','Seyahat sırasında kullanışlı temel ifade.','Merhaba','mehr-hah-bah','Hello')
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000011'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000011'::uuid,'41000000-0000-0000-0000-000000000011'::uuid,'en','en','Thank you','Useful everywhere.','Teşekkür ederim','teh-shek-kur eh-deh-rim','Thank you')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000011'::uuid,'41000000-0000-0000-0000-000000000011'::uuid,'tr','tr','Thank you','Seyahat sırasında kullanışlı temel ifade.','Teşekkür ederim','teh-shek-kur eh-deh-rim','Thank you')
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('41000000-0000-0000-0000-000000000012'::uuid,(select id from public.countries where code='TR'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='TR' and lower(ci.default_name)=lower('Istanbul') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000012'::uuid,'41000000-0000-0000-0000-000000000012'::uuid,'en','en','How much?','Useful in markets and shops.','Ne kadar?','neh kah-dahr','How much?')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('41000000-0000-0000-0000-000000000012'::uuid,'41000000-0000-0000-0000-000000000012'::uuid,'tr','tr','How much?','Seyahat sırasında kullanışlı temel ifade.','Ne kadar?','neh kah-dahr','How much?')
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000001'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'doTip',10,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000001'::uuid,'42000000-0000-0000-0000-000000000001'::uuid,'en','en','Queue in order','Follow platform markings and wait in line for trains and shops.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000001'::uuid,'42000000-0000-0000-0000-000000000001'::uuid,'tr','tr','Queue in order','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000002'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'dontTip',10,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000002'::uuid,'42000000-0000-0000-0000-000000000002'::uuid,'en','en','Keep calls quiet','Avoid loud phone calls on trains and other shared spaces.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000002'::uuid,'42000000-0000-0000-0000-000000000002'::uuid,'tr','tr','Keep calls quiet','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000003'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'tipping',9,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000003'::uuid,'42000000-0000-0000-0000-000000000003'::uuid,'en','en','Tipping','Tipping is generally not expected in everyday restaurants.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000003'::uuid,'42000000-0000-0000-0000-000000000003'::uuid,'tr','tr','Tipping','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000004'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'transport',10,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000004'::uuid,'42000000-0000-0000-0000-000000000004'::uuid,'en','en','Train etiquette','Let passengers exit first and keep bags from blocking aisles.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000004'::uuid,'42000000-0000-0000-0000-000000000004'::uuid,'tr','tr','Train etiquette','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000005'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'religiousPlace',9,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000005'::uuid,'42000000-0000-0000-0000-000000000005'::uuid,'en','en','Temple and shrine etiquette','Observe signs, keep voices low, and avoid interrupting worship.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000005'::uuid,'42000000-0000-0000-0000-000000000005'::uuid,'tr','tr','Temple and shrine etiquette','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000006'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'touristMistake',7,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000006'::uuid,'42000000-0000-0000-0000-000000000006'::uuid,'en','en','Eating while walking','In many areas it is better to finish food near where you bought it.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000006'::uuid,'42000000-0000-0000-0000-000000000006'::uuid,'tr','tr','Eating while walking','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000007'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'safety',7,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000007'::uuid,'42000000-0000-0000-0000-000000000007'::uuid,'en','en','Last train planning','Check your last train before a late evening out.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000007'::uuid,'42000000-0000-0000-0000-000000000007'::uuid,'tr','tr','Last train planning','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000008'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'scam',9,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000008'::uuid,'42000000-0000-0000-0000-000000000008'::uuid,'en','en','Nightlife touts','Be cautious with persistent touts in nightlife districts.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000008'::uuid,'42000000-0000-0000-0000-000000000008'::uuid,'tr','tr','Nightlife touts','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000009'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'doTip',6,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000009'::uuid,'42000000-0000-0000-0000-000000000009'::uuid,'en','en','Cash tray etiquette','Use the payment tray when a shop provides one.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000009'::uuid,'42000000-0000-0000-0000-000000000009'::uuid,'tr','tr','Cash tray etiquette','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000010'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000010'::uuid,'42000000-0000-0000-0000-000000000010'::uuid,'en','en','This one, please','Useful when ordering.','これをください','Kore o kudasai','This one, please.')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000010'::uuid,'42000000-0000-0000-0000-000000000010'::uuid,'tr','tr','This one, please','Seyahat sırasında kullanışlı temel ifade.','これをください','Kore o kudasai','This one, please.')
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000011'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000011'::uuid,'42000000-0000-0000-0000-000000000011'::uuid,'en','en','Thank you very much','Polite and widely useful.','ありがとうございます','Arigatou gozaimasu','Thank you very much.')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000011'::uuid,'42000000-0000-0000-0000-000000000011'::uuid,'tr','tr','Thank you very much','Seyahat sırasında kullanışlı temel ifade.','ありがとうございます','Arigatou gozaimasu','Thank you very much.')
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('42000000-0000-0000-0000-000000000012'::uuid,(select id from public.countries where code='JP'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='JP' and lower(ci.default_name)=lower('Tokyo') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000012'::uuid,'42000000-0000-0000-0000-000000000012'::uuid,'en','en','Excuse me','Useful for getting attention politely.','すみません','Sumimasen','Excuse me / sorry.')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('42000000-0000-0000-0000-000000000012'::uuid,'42000000-0000-0000-0000-000000000012'::uuid,'tr','tr','Excuse me','Seyahat sırasında kullanışlı temel ifade.','すみません','Sumimasen','Excuse me / sorry.')
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000001'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'doTip',9,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000001'::uuid,'43000000-0000-0000-0000-000000000001'::uuid,'en','en','Respect church dress codes','Some churches expect shoulders and knees to be covered.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000001'::uuid,'43000000-0000-0000-0000-000000000001'::uuid,'tr','tr','Respect church dress codes','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000002'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'dontTip',8,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000002'::uuid,'43000000-0000-0000-0000-000000000002'::uuid,'en','en','Do not sit on protected monuments','Follow local signs around historic monuments and fountains.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000002'::uuid,'43000000-0000-0000-0000-000000000002'::uuid,'tr','tr','Do not sit on protected monuments','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000003'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'tipping',8,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000003'::uuid,'43000000-0000-0000-0000-000000000003'::uuid,'en','en','Tipping','Tipping is optional; service charges may already be included.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000003'::uuid,'43000000-0000-0000-0000-000000000003'::uuid,'tr','tr','Tipping','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000004'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'transport',8,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000004'::uuid,'43000000-0000-0000-0000-000000000004'::uuid,'en','en','Validate tickets','Check whether your local transit ticket needs validation.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000004'::uuid,'43000000-0000-0000-0000-000000000004'::uuid,'tr','tr','Validate tickets','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000005'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'religiousPlace',9,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000005'::uuid,'43000000-0000-0000-0000-000000000005'::uuid,'en','en','Church visits','Keep voices low and respect active services.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000005'::uuid,'43000000-0000-0000-0000-000000000005'::uuid,'tr','tr','Church visits','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000006'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'touristMistake',6,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000006'::uuid,'43000000-0000-0000-0000-000000000006'::uuid,'en','en','Ordering coffee','A cappuccino is commonly associated with breakfast rather than after dinner.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000006'::uuid,'43000000-0000-0000-0000-000000000006'::uuid,'tr','tr','Ordering coffee','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000007'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'safety',10,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000007'::uuid,'43000000-0000-0000-0000-000000000007'::uuid,'en','en','Crowded areas','Keep valuables secure on busy public transport and near major sights.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000007'::uuid,'43000000-0000-0000-0000-000000000007'::uuid,'tr','tr','Crowded areas','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000008'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'scam',10,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000008'::uuid,'43000000-0000-0000-0000-000000000008'::uuid,'en','en','Unwanted gifts','Be cautious if strangers aggressively offer bracelets or gifts.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000008'::uuid,'43000000-0000-0000-0000-000000000008'::uuid,'tr','tr','Unwanted gifts','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000009'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'doTip',6,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000009'::uuid,'43000000-0000-0000-0000-000000000009'::uuid,'en','en','Stand at the bar','Coffee at the bar can be a different experience and price from table service.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000009'::uuid,'43000000-0000-0000-0000-000000000009'::uuid,'tr','tr','Stand at the bar','Yerel kurallara, işaretlere ve ortak alan kullanımına saygı göster.',null,null,null)
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000010'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000010'::uuid,'43000000-0000-0000-0000-000000000010'::uuid,'en','en','Hello','A friendly basic greeting.','Buongiorno','bwon-JOR-no','Good morning / hello')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000010'::uuid,'43000000-0000-0000-0000-000000000010'::uuid,'tr','tr','Hello','Seyahat sırasında kullanışlı temel ifade.','Buongiorno','bwon-JOR-no','Good morning / hello')
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000011'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000011'::uuid,'43000000-0000-0000-0000-000000000011'::uuid,'en','en','Thank you','Useful everywhere.','Grazie','GRA-tsyeh','Thank you')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000011'::uuid,'43000000-0000-0000-0000-000000000011'::uuid,'tr','tr','Thank you','Seyahat sırasında kullanışlı temel ifade.','Grazie','GRA-tsyeh','Thank you')
on conflict do nothing;

insert into public.culture_guide_items (id,country_id,city_id,tip_type,priority,is_published)
values ('43000000-0000-0000-0000-000000000012'::uuid,(select id from public.countries where code='IT'),(select ci.id from public.cities ci join public.countries co on co.id=ci.country_id where co.code='IT' and lower(ci.default_name)=lower('Rome') order by ci.created_at asc limit 1),'phrase',5,true)
on conflict (id) do update set country_id=excluded.country_id,city_id=excluded.city_id,tip_type=excluded.tip_type,priority=excluded.priority,is_published=true,updated_at=now();

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000012'::uuid,'43000000-0000-0000-0000-000000000012'::uuid,'en','en','How much?','Useful when shopping.','Quanto costa?','KWAN-toh KOS-tah','How much does it cost?')
on conflict do nothing;

insert into public.culture_guide_translations (item_id,guide_item_id,language_code,locale,title,body,phrase_local,phrase_pronunciation,phrase_translation)
values ('43000000-0000-0000-0000-000000000012'::uuid,'43000000-0000-0000-0000-000000000012'::uuid,'tr','tr','How much?','Seyahat sırasında kullanışlı temel ifade.','Quanto costa?','KWAN-toh KOS-tah','How much does it cost?')
on conflict do nothing;

select co.code as country_code,ci.default_name as city,count(*) filter (where c.status='published') as published_contents
from public.contents c join public.cities ci on ci.id=c.city_id join public.countries co on co.id=ci.country_id
where co.code in ('TR','JP','IT') group by co.code,ci.default_name order by co.code,ci.default_name;

select category_id,count(*) as item_count from public.contents
where id::text like '31%' or id::text like '32%' or id::text like '33%'
group by category_id order by category_id;
