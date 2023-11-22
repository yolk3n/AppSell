﻿
Процедура ЗагрузитьДанные(Лог,ПерезаписыватьДокументы) Экспорт
	
	
		НастройкиОбмена = ПолучитьНастройкиОбмена();
	
	HTTPСоединение = Новый HTTPСоединение(НастройкиОбмена.АдресСервиса,443,НастройкиОбмена.Логин,НастройкиОбмена.Пароль,,,Новый ЗащищенноеСоединениеOpenSSL(),);		
	HTTPЗапрос = Новый HTTPЗапрос("/service-api/1c/updates?limit=100");	
	Сч = 1;	
	ЕстьДокументы = Истина;
	Пока ЕстьДокументы  Цикл
		
		HTTPОтвет    = HTTPСоединение.Получить(HTTPЗапрос);	
		Ответ = Новый Структура("Код, ДанныеОтвета",0,"");
		ДанныеОтвета = Неопределено;
		
		Ответ.Вставить("Код", HTTPОтвет.КодСостояния);
		
		
		Если Ответ.Код = 200 Тогда
			
			ДанныеОтвета = HTTPОтвет.ПолучитьТелоКакСтроку();
			Чтение = Новый ЧтениеJSON;
			Чтение.УстановитьСтроку(ДанныеОтвета);
			ДанныеОтвета = ПрочитатьJSON(Чтение, Истина);
			
		Иначе
			Лог.Добавить("Ошибка подключения код: " + HTTPОтвет.КодСостояния); 
			ЕстьДокументы = Ложь;
			Прервать;
		КонецЕсли;
		
		Если ТипЗнч(ДанныеОтвета) = Тип("Массив") тогда
			
			Если ДанныеОтвета.Количество() тогда
				
				Лог.Добавить("Количество объектов для загрузки: " + ДанныеОтвета.Количество());
				
				Для Каждого СоответствиеДанных из ДанныеОтвета Цикл 
					
					СтруктураОшибок = Новый Структура;
					СтруктураОшибок.Вставить("Контрагент",Новый Структура("success,message"));
					СтруктураОшибок.Вставить("БанковскийСчет",Новый Структура("success,message"));
					СтруктураОшибок.Вставить("УПД",Новый Структура("success,message"));
					
					
					Контрагент = Неопределено;
					
					//1.Получим структуру контрагента;
					СоответствиеКонтрагент = СоответствиеДанных.Получить("Контрагент");		
					Если СоответствиеКонтрагент <> Неопределено тогда
						СтруктураКонтрагент = ПолучитьСтруктуруИзСоответствия(СоответствиеКонтрагент.Получить("#value"));			
						Контрагент = СоздатьЗаполнитьКонтрагента(СтруктураКонтрагент,СтруктураОшибок,НастройкиОбмена);
						Договор = СоздатьЗаполнитьДоговор(Контрагент,НастройкиОбмена); 
					КонецЕсли; 
					
					//2.Получим структуру банковского счета;
					СоответствиеБанкСчет = СоответствиеДанных.Получить("БанковскийСчет");		
					Если СоответствиеБанкСчет <> Неопределено тогда
						СтруктураБанкСчет = ПолучитьСтруктуруИзСоответствия(СоответствиеБанкСчет.Получить("#value"));
						Если Контрагент <> Неопределено тогда
							СтруктураБанкСчет.Вставить("Владелец",Контрагент); 
							СоздатьЗаполнитьБанковскийСчет(СтруктураБанкСчет,СтруктураОшибок,НастройкиОбмена);
						Иначе
							СтруктураОшибок.БанковскийСчет.Вставить("success",Ложь);
							СтруктураОшибок.БанковскийСчет.Вставить("message","Не заполнен контрагент");
						КонецЕсли;
					КонецЕсли; 
					
					//3.Получим структуру УПД
					
					СоответствиеУПД = СоответствиеДанных.Получить("УПД");		
					Если СоответствиеУПД <> Неопределено тогда
						СтруктураУПД = ПолучитьСтруктуруИзСоответствия(СоответствиеУПД.Получить("#value"));
						Если Контрагент <> Неопределено тогда
							СтруктураУПД.Вставить("Контрагент",Контрагент);
							СтруктураУПД.Вставить("ДоговорКонтрагента",Договор);
							СтруктураУПД.Вставить("ПерезаписыватьДокументы",ПерезаписыватьДокументы);
							УПД = СоздатьЗаполнитьУПД(СтруктураУПД,СтруктураОшибок,НастройкиОбмена);
						Иначе
							СтруктураОшибок.УПД.Вставить("success",Ложь);
							СтруктураОшибок.УПД.Вставить("message","Не заполнен контрагент");
						КонецЕсли;
					КонецЕсли;
					
					id = СоответствиеДанных.Получить("id"); 
					
					//4. Логи, журнал и уведомления
					ЗаписатьВЖурнал(СтруктураОшибок,Контрагент,УПД);
					
					Лог.Добавить("" + Сч +": " + id);					
					Лог.Добавить("Контрагент: " + СтруктураОшибок.Контрагент.message + " "  + Контрагент);
					Лог.Добавить("Банковский счет:" + СтруктураОшибок.БанковскийСчет.message);
					Лог.Добавить("УПД:" + СтруктураОшибок.УПД.message + " " +УПД);	
					
					
					//Если что-то пошло не так, отправляем уведомление
					
					Если 	НЕ СтруктураОшибок.УПД.success ИЛИ
							НЕ СтруктураОшибок.БанковскийСчет.success ИЛИ
							НЕ СтруктураОшибок.УПД.success тогда 
						
						Если ЗначениеЗаполнено(НастройкиОбмена.emailУведомлений) тогда
							ПараметрыПисьма = Новый Структура;
							ПараметрыПисьма.Вставить("Контрагент",Контрагент);
							ПараметрыПисьма.Вставить("УПД",УПД); 
							ПараметрыПисьма.Вставить("СтруктураОшибок",СтруктураОшибок);
							ОтправитьУведомление(ПараметрыПисьма,НастройкиОбмена);
						КонецЕсли;
						
					КонецЕсли; 				
					
					
					//5. Отправляем PUT запрос в сервис со статусами ошибок.
					ЗаписьJSON = Новый ЗаписьJSON;
					тПараметрыJSON = Новый ПараметрыЗаписиJSON(ПереносСтрокJSON.Нет, " ", Истина);  
					ЗаписьJSON.УстановитьСтроку(тПараметрыJSON); 
					ЗаписатьJSON(ЗаписьJSON, СтруктураОшибок);
					СтрокаJS = ЗаписьJSON.Закрыть();
					
					
					HTTPСоединениеPUT = Новый HTTPСоединение(НастройкиОбмена.АдресСервиса,443,НастройкиОбмена.Логин,НастройкиОбмена.Пароль,,,Новый ЗащищенноеСоединениеOpenSSL(),);		
	
					HTTPЗапросPUT = Новый HTTPЗапрос("/service-api/1c/updates/"+ id + "/received");
					HTTPЗапросPUT.Заголовки.Вставить("Content-type", "application/json");
					HTTPЗапросPUT.УстановитьТелоИзСтроки(СтрокаJS,КодировкаТекста.UTF8,ИспользованиеByteOrderMark.НеИспользовать);
					Результат = HTTPСоединениеPUT.ВызватьHTTPМетод("PUT",HTTPЗапросPUT); 	
				
								
					Сч = Сч + 1;
					
				КонецЦикла;
				
			Иначе  	
				
				ЕстьДокументы = Ложь;
				Лог.Добавить("Нет данных для загрузки");
				Прервать; 
				
			КонецЕсли; 
		Иначе
			ЕстьДокументы = Ложь;
			Лог.Добавить("Нет данных для загрузки");
			Прервать;                               		
		КонецЕсли;
	КонецЦикла;
	
КонецПроцедуры  

Функция СоздатьЗаполнитьКонтрагента(Структура,СтруктураОшибок,НастройкиОбмена)
	
	Структура.Удалить("КонтактнаяИнформация");
	
	КонтрагентСсылка = Справочники.Контрагенты.ПолучитьСсылку(Новый УникальныйИдентификатор(Структура.Ref));
	КонтрагентОбъект = КонтрагентСсылка.ПолучитьОбъект();
	//Создаем нового контрагента 
	Если  КонтрагентОбъект = Неопределено Тогда 	 
		
		//Для начала поищем по ИНН, вдруг уже есть такой до первой выгрузке		
		КонтрагентИНН = Неопределено;
		
		Если ЗначениеЗаполнено(Структура.ИНН) тогда
			КонтрагентИНН = Справочники.Контрагенты.НайтиПоРеквизиту("ИНН",Структура.ИНН);
		КонецЕсли;
		
		Если НЕ ЗначениеЗаполнено(КонтрагентИНН) Тогда				
			КонтрагентОбъект = Справочники.Контрагенты.СоздатьЭлемент();
			КонтрагентОбъект.УстановитьСсылкуНового(КонтрагентСсылка);
			ЭтоЮрлицо = Истина;
			Если СтрДлина(СокрЛП(Структура.ИНН)) = 10 тогда			
				Структура.Вставить("ЮридическоеФизическоеЛицо",Перечисления.ЮридическоеФизическоеЛицо.ЮридическоеЛицо);				
				РеквизитыКонтрагента = РаботаСКонтрагентами.СведенияОЮридическомЛицеПоИНН(СокрЛП(Структура.ИНН)); 
			ИначеЕсли  СтрДлина(СокрЛП(Структура.ИНН)) = 12 тогда  
				ЭтоЮрлицо = Ложь;
				Структура.Вставить("ЮридическоеФизическоеЛицо",Перечисления.ЮридическоеФизическоеЛицо.ФизическоеЛицо);			
				РеквизитыКонтрагента = РаботаСКонтрагентами.РеквизитыПредпринимателяПоИНН(СокрЛП(Структура.ИНН));
			Иначе
				СтруктураОшибок.Вставить("Контрагент", Новый Структура("success,message",false,"ИНН должен содержать 10 или 12 знаков"));
				Возврат Неопределено;	
			КонецЕсли; 
			
			Если СокрЛП(РеквизитыКонтрагента.ОписаниеОшибки) = "" Тогда 
				Если ЭтоЮрЛицо тогда 				
					КонтрагентОбъект.Заполнить(РеквизитыКонтрагента.ЕГРЮЛ);				
					УправлениеКонтактнойИнформацией.ЗаписатьКонтактнуюИнформацию(КонтрагентОбъект,РеквизитыКонтрагента.ЕГРЮЛ.ЮридическийАдрес.КонтактнаяИнформация,Справочники.ВидыКонтактнойИнформации.ЮрАдресКонтрагента,Перечисления.ТипыКонтактнойИнформации.Адрес,,ТекущаяДата());
					Если РеквизитыКонтрагента.ЕГРЮЛ.Руководители.Количество() тогда
						КонтрагентОбъект.ОсновноеКонтактноеЛицо = НовоеОсновноеКонтактноеЛицо(КонтрагентОбъект,РеквизитыКонтрагента.ЕГРЮЛ.Руководители[0]);
					КонецЕсли; 				
				Иначе //Это физическое лицо 
					КонтрагентОбъект.Заполнить(РеквизитыКонтрагента);
					КонтрагентОбъект.ЮридическоеФизическоеЛицо = Перечисления.ЮридическоеФизическоеЛицо.ФизическоеЛицо;
				КонецЕсли;
				
			Иначе
				СтруктураОшибок.Вставить("Контрагент", Новый Структура("success,message",false,РеквизитыКонтрагента.ОписаниеОшибки));
				Возврат Неопределено;
			КонецЕсли;  
			
			КонтрагентОбъект.Родитель = НастройкиОбмена.ГруппаКонтрагентов;	
			
			Попытка
				КонтрагентОбъект.Записать(); 
				СтруктураОшибок.Вставить("Контрагент", Новый Структура("success,message",true,"записан " + КонтрагентОбъект.Наименование));
				Возврат КонтрагентОбъект.Ссылка;
			Исключение
				СтруктураОшибок.Вставить("Контрагент", Новый Структура("success,message",false,"ошибка записи"));
				Возврат Неопределено;
			КонецПопытки;
		Иначе 
			СтруктураОшибок.Вставить("Контрагент", Новый Структура("success,message",true,"найден по ИНН " + КонтрагентИНН.Наименование ));
			Возврат КонтрагентИНН; 	
		КонецЕсли;
	Иначе
		СтруктураОшибок.Вставить("Контрагент", Новый Структура("success,message",true,"найден " + КонтрагентОбъект.Наименование ));
		Возврат КонтрагентСсылка; 
	КонецЕсли;
	
КонецФункции 

Функция СоздатьЗаполнитьДоговор(Контрагент,НастройкиОбмена)
	
	Наименование =   НастройкиОбмена.НаименованиеДоговора;
	
	Договор  = Справочники.ДоговорыКонтрагентов.НайтиПоНаименованию(Наименование,Истина,,Контрагент);
	Если Договор = Справочники.ДоговорыКонтрагентов.ПустаяСсылка() тогда 	
		НовыйДоговор = Справочники.ДоговорыКонтрагентов.СоздатьЭлемент();
		НовыйДоговор.Наименование = Наименование;
		НовыйДоговор.ВалютаВзаиморасчетов = ОбщегоНазначенияБПВызовСервераПовтИсп.ПолучитьВалютуРегламентированногоУчета();
		НовыйДоговор.Владелец = Контрагент;
		НовыйДоговор.ВидДоговора = Перечисления.ВидыДоговоровКонтрагентов.СПоставщиком;
		НовыйДоговор.Организация =НастройкиОбмена.Организация; 
		НовыйДоговор.Записать();
		Договор =  НовыйДоговор.Ссылка;
	КонецЕсли;
	
	Возврат Договор;
	
КонецФункции

Функция НовоеОсновноеКонтактноеЛицо(ТекущийОбъект,КонтактноеЛицо)
	
	ЗначенияЗаполнения = Новый Структура;
	ЗначенияЗаполнения.Вставить("Наименование", КонтактноеЛицо.Представление);
	ЗначенияЗаполнения.Вставить("Должность", КонтактноеЛицо.Должность);
	ЗначенияЗаполнения.Вставить("ОбъектВладелец", ТекущийОбъект.Ссылка);
	ЗначенияЗаполнения.Вставить("ВидКонтактногоЛица", Перечисления.ВидыКонтактныхЛиц.КонтактноеЛицоКонтрагента);
	
	ПараметрыСоздания = Новый Структура;
	ПараметрыСоздания.Вставить("ЗначенияЗаполнения", ЗначенияЗаполнения);
	
	Возврат Справочники.КонтактныеЛица.СоздатьКонтактноеЛицо(ПараметрыСоздания);
	
КонецФункции

Процедура СоздатьЗаполнитьБанковскийСчет(Структура,СтруктураОшибок,НастройкиОбмена)
	
	Если СтруктураОшибок.Контрагент.success = Ложь тогда
		СтруктураОшибок.Вставить("БанковскийСчет",Новый Структура("success,message",false,"не загружен контрагент"));
		Возврат
	КонецЕсли;
	
	Владелец = Структура.Владелец;
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ ПЕРВЫЕ 1
	|	БанковскиеСчета.Ссылка КАК Ссылка
	|ИЗ
	|	Справочник.БанковскиеСчета КАК БанковскиеСчета
	|ГДЕ
	|	БанковскиеСчета.Владелец = &Владелец
	|	И БанковскиеСчета.НомерСчета = &НомерСчета"; 
	Запрос.УстановитьПараметр("Владелец",Структура.Владелец);
	Запрос.УстановитьПараметр("НомерСчета",Структура.НомерСчета);
	
	Результат = Запрос.Выполнить();
	Выборка = Результат.Выбрать();
	Если Выборка.Следующий() тогда
		СтруктураОшибок.Вставить("БанковскийСчет", Новый Структура("success,message",true,"найден"));
		Возврат;
	КонецЕсли; 
	
	Банк = Справочники.Банки.НайтиБанкТолькоПоБИК(Структура.Банк); 
	Если Банк = Неопределено тогда
		ДанныеЗаполнения = Новый Структура;
		ДанныеЗаполнения.Вставить("БИК",Структура.Банк);
		Если РаботаСБанкамиБП.УстановитьБанк(ДанныеЗаполнения) тогда
			Банк = ДанныеЗаполнения.Банк;
		КонецЕсли;
	КонецЕсли;
	
	Если Банк = Неопределено тогда
		СтруктураОшибок.Вставить("БанковскийСчет",Новый Структура("success,message",false,"не найдет банк "+Структура.Банк+", требуется обновить классификатор")); 
	Иначе 
		
		Структура.Вставить("Банк",Банк);
		Структура.Вставить("ВалютаДенежныхСредств",ОбщегоНазначенияБПВызовСервераПовтИсп.ПолучитьВалютуРегламентированногоУчета());
		
		Если БанковскиеСчетаФормыКлиентСервер.НомерСчетаКорректен(Структура.НомерСчета, Структура.Банк.Код, Истина, "") Тогда
			
			НовыйБанкСчет = Справочники.БанковскиеСчета.СоздатьЭлемент();
			НовыйБанкСчет.Владелец = Структура.Владелец; 
			НовыйБанкСчет.Заполнить(Структура);
			НовыйБанкСчет.Наименование = Структура.НомерСчета + ", " + Структура.Банк.Наименование; 
			НовыйБанкСчет.Записать();
			СтруктураОшибок.Вставить("БанковскийСчет", Новый Структура("success,message",true,"создан"));
		Иначе		
			СтруктураОшибок.Вставить("БанковскийСчет",Новый Структура("success,message",false,"не корректен номер счета"));
		КонецЕсли; 
	КонецЕсли;
	
КонецПроцедуры

Функция СоздатьЗаполнитьУПД(Структура,СтруктураОшибок,НастройкиОбмена)
	
	Если СтруктураОшибок.Контрагент.success = Ложь тогда
		СтруктураОшибок.Вставить("УПД",Новый Структура("success,message",false,"не загружен контрагент"));
		Возврат Неопределено;
	КонецЕсли;
	
	ПерезаписыватьДокументы = Структура.ПерезаписыватьДокументы;
	
	ПоступлениеСсылка = Документы.ПоступлениеТоваровУслуг.ПолучитьСсылку(Новый УникальныйИдентификатор(Структура.Ref));
	ПоступлениеОбъект = ПоступлениеСсылка.ПолучитьОбъект();  
	
	Если ПоступлениеОбъект = Неопределено ИЛИ ПерезаписыватьДокументы тогда
		
		Если НЕ Структура.Услуги.Количество() тогда			
			СтруктураОшибок.Вставить("УПД",Новый Структура("success,message",false,"нет услуг"));
			Возврат Неопределено;
		КонецЕсли;
		
		Если  ПоступлениеОбъект = Неопределено тогда			
		ПоступлениеОбъект = Документы.ПоступлениеТоваровУслуг.СоздатьДокумент();
		ПоступлениеОбъект.УстановитьСсылкуНового(ПоступлениеСсылка);		
		КонецЕсли; 
	
		ПоступлениеОбъект.Заполнить(Структура);
		
		ПоступлениеОбъект.Услуги.Очистить();
		
		ПоступлениеОбъект.Дата = XMLЗначение(Тип("Дата"),Структура.Date);
		ПоступлениеОбъект.ДатаВходящегоДокумента = XMLЗначение(Тип("Дата"),Структура.Date); 
		ПоступлениеОбъект.НомерВходящегоДокумента = ?(ЗначениеЗаполнено(Структура.Number),Структура.Number,"б/н");		
		ПоступлениеОбъект.Организация = НастройкиОбмена.Организация; 
		ПоступлениеОбъект.ВидОперации = Перечисления.ВидыОперацийПоступлениеТоваровУслуг.Услуги;                                                                  
		ПоступлениеОбъект.НДСВключенВСтоимость = Ложь; 
		ПоступлениеОбъект.СуммаВключаетНДС = Структура.СуммаВключаетНДС;
		
		
		ПоступлениеОбъект.ДоговорКонтрагента = Структура.ДоговорКонтрагента;
		ПоступлениеОбъект.Комментарий = "Загружен из Appsell"; 
		
		РаздельныйУчетНДСНаСчете19   = УчетнаяПолитика.РаздельныйУчетНДСНаСчете19(ПоступлениеОбъект.Организация, ПоступлениеОбъект.Дата);
		
		Для Каждого Услуга из Структура.Услуги Цикл
			
			НоваяСтрока = ПоступлениеОбъект.Услуги.Добавить();
			ЗаполнитьЗначенияСвойств(НоваяСтрока,Услуга);     
			НоваяСтрока.Номенклатура = НайтиСоздатьНоменклатуру(Услуга,НастройкиОбмена); 
			
			Если Услуга.СтавкаНДС = "БезНДС" тогда				
				ПеречислениеСтавкаНДС =  Перечисления.ВидыСтавокНДС.БезНДС;
			Иначе // общая ставка
				ПеречислениеСтавкаНДС = Перечисления.ВидыСтавокНДС.Общая ;
			КонецЕсли;			
			НоваяСтрока.СтавкаНДС = Перечисления.СтавкиНДС.СтавкаНДС(ПеречислениеСтавкаНДС,ТекущаяДата());			
			
			ОбработкаТабличныхЧастейКлиентСервер.РассчитатьСуммуТабЧасти(НоваяСтрока, 0);
			ОбработкаТабличныхЧастейКлиентСервер.РассчитатьСуммуНДСТабЧасти(НоваяСтрока, ПоступлениеОбъект.СуммаВключаетНДС);
			
			НоваяСтрока.СчетЗатрат = ПланыСчетов.Хозрасчетный.ОбщехозяйственныеРасходы;	
			НоваяСтрока.СчетЗатратНУ = НоваяСтрока.СчетЗатрат;
			НоваяСтрока.Субконто1 = НастройкиОбмена.СтатьяЗатрат;		
			НоваяСтрока.ПодразделениеЗатрат = НастройкиОбмена.ПодразделениеЗатрат;		
			НоваяСтрока.СубконтоНУ1 = НоваяСтрока.Субконто1; 
			НоваяСтрока.СчетУчетаНДС =  НастройкиОбмена.СчетУчетаНДСУслуг;
			НоваяСтрока.СпособУчетаНДС = Перечисления.СпособыУчетаНДС.ПринимаетсяКВычету;
			
		КонецЦикла;
		
		ПоступлениеОбъект.ЭтоУниверсальныйДокумент = Истина;
		ПоступлениеОбъект.Записать();
		message = "создан ";
		Если ПерезаписыватьДокументы тогда
			message = "изменен "
		КонецЕсли;
		СтруктураОшибок.Вставить("УПД",Новый Структура("success,message",true,message + ПоступлениеОбъект.Номер));
				
		СоздатьПлатежноеПоручение(ПоступлениеОбъект.Ссылка)
		
		
		
		
	Иначе 
		СтруктураОшибок.Вставить("УПД",Новый Структура("success,message",false,"загружен ранее " + ПоступлениеОбъект.Номер));
	КонецЕсли;   	
	Возврат ПоступлениеОбъект.Ссылка; 	
КонецФункции

Процедура СоздатьПлатежноеПоручение(ПоступлениеСсылка)  
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ПлатежноеПоручение.Ссылка КАК Ссылка
		|ИЗ
		|	Документ.ПлатежноеПоручение КАК ПлатежноеПоручение
		|ГДЕ
		|	ПлатежноеПоручение.ДокументОснование = &ДокументОснование";
	
	Запрос.УстановитьПараметр("ДокументОснование", ПоступлениеСсылка);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	ПлатежноеПоручениеОбъект = Неопределено;
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл 
		
		ПлатежноеПоручение =  ВыборкаДетальныеЗаписи.Ссылка;
		ПлатежноеПоручениеОбъект = ПлатежноеПоручение.ПолучитьОбъект(); 	
		
	КонецЦикла;
	
	Если ПлатежноеПоручениеОбъект = Неопределено тогда
		Документ = Документы.ПлатежноеПоручение.СоздатьДокумент();
	Иначе
		Документ = ПлатежноеПоручениеОбъект;
	КонецЕсли;  
	
	Документ.Заполнить(ПоступлениеСсылка);
	Документ.Записать(РежимЗаписиДокумента.Запись);
	
КонецПроцедуры

Функция НайтиСоздатьНоменклатуру(Структура,НастройкиОбмена) 
	
	Родитель = НастройкиОбмена.ГруппаНоменклатуры;
	
	Номенклатура = Справочники.Номенклатура.НайтиПоНаименованию(Структура.Содержание,Истина,Родитель);
	
	Если НЕ ЗначениеЗаполнено(Номенклатура) тогда
		НоваяНоменклатура = Справочники.Номенклатура.СоздатьЭлемент();
		НоваяНоменклатура.Услуга = Истина;
		НоваяНоменклатура.Заполнить(Структура);
		НоваяНоменклатура.Родитель = Родитель; 
		НоваяНоменклатура.Наименование = Структура.Содержание;
		НоваяНоменклатура.НаименованиеПолное = Структура.Содержание;
		НоваяНоменклатура.ВидНоменклатуры = Справочники.ВидыНоменклатуры.НайтиПоНаименованию("Услуги");
		НоваяНоменклатура.Записать();
		Возврат НоваяНоменклатура.Ссылка;		
	Иначе 		
		Возврат Номенклатура; 
	КонецЕсли;  
	
КонецФункции

Функция ПолучитьСтруктуруИзСоответствия(ЗначВход) Экспорт
	
	СтруктураВозврат=Новый Структура;
	
	Если ТипЗнч(ЗначВход)=Тип("Соответствие") Тогда
		
		ФлагОшибка=Ложь;
		
		Для Каждого р Из ЗначВход Цикл
			Попытка
				СтруктураВозврат.Вставить(р.Ключ,ПолучитьСтруктуруИзСоответствия(р.Значение));
			Исключение
				ФлагОшибка=Истина;
				Прервать;
			КонецПопытки;
		КонецЦикла;
		
		Если ФлагОшибка Тогда // пришел ключ который не возможно поместить в структуру
			СтруктураВозврат = Новый Массив;
			Для Каждого р Из ЗначВход Цикл
				ДопСтруктура=Новый Структура;
				ДопСтруктура.Вставить("Ключ",р.Ключ);
				ДопСтруктура.Вставить("Значение",ПолучитьСтруктуруИзСоответствия(р.Значение));
				СтруктураВозврат.Добавить(ДопСтруктура);
			КонецЦикла;
		КонецЕсли;
		
		Возврат СтруктураВозврат; 
		
	ИначеЕсли ТипЗнч(ЗначВход)=Тип("Массив") Тогда
		
		НовыйМассив=Новый Массив;
		Для Каждого ЭлМ Из ЗначВход Цикл
			НовыйМассив.Добавить(ПолучитьСтруктуруИзСоответствия(ЭлМ));
		КонецЦикла;
		Возврат НовыйМассив;
		
	КонецЕсли;
	
	Возврат ЗначВход; 
	
КонецФункции

Процедура ЗаписатьВЖурнал(СтруктураОшибок,Контрагент,УПД)
	
	ЗаписьJSON = Новый ЗаписьJSON;			
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON,СтруктураОшибок);			
	JSON =  ЗаписьJSON.Закрыть();   
	
	СписокЗаписейЖурнала = Новый СписокЗначений();   
	ЗаписьЖурналаКонец = Новый Структура("ИмяСобытия, ПредставлениеУровня, Комментарий,ДатаСобытия");
	ЗаписьЖурналаКонец.ИмяСобытия = "Обмен Appsell";
	ЗаписьЖурналаКонец.ПредставлениеУровня = "Информация"; 
	ЗаписьЖурналаКонец.Комментарий = Строка(Контрагент) + Символы.ПС + Строка(УПД) + Символы.ПС + JSON;
	ЗаписьЖурналаКонец.ДатаСобытия = ТекущаяДата();
	
	СписокЗаписейЖурнала.Добавить(ЗаписьЖурналаКонец); 
	ЖурналРегистрации.ЗаписатьСобытияВЖурналРегистрации(СписокЗаписейЖурнала);
	
	
КонецПроцедуры


Функция ПолучитьНастройкиОбмена()
	
	Настройки = Новый Структура;
	Настройки.Вставить("ГруппаКонтрагентов",		ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ГруппаКонтрагентов));
	Настройки.Вставить("НаименованиеДоговора",      ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.НаименованиеДоговора));
	Настройки.Вставить("НаименованиеДоговора",      ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.НаименованиеДоговора));
	Настройки.Вставить("emailУведомлений",      	ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.emailУведомлений));
	Настройки.Вставить("АдресСервиса",      		ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.АдресСервиса));
	Настройки.Вставить("Логин",     				ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.Логин));
	Настройки.Вставить("Пароль",      				ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.Пароль));
	Настройки.Вставить("ГруппаНоменклатуры",        ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ГруппаНоменклатуры));
	Настройки.Вставить("Организация",      			ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.Организация));
	Настройки.Вставить("ПодразделениеЗатрат",       ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ПодразделениеЗатрат));
	Настройки.Вставить("СтатьяЗатрат",      		ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.СтатьяЗатрат));
	Настройки.Вставить("СчетУчетаНДСУслуг",      	ПланыВидовХарактеристик.бит_НастройкиЗагрузки.ЗначениеНастройки(ПланыВидовХарактеристик.бит_НастройкиЗагрузки.СчетУчетаНДСУслуг));
	
	Возврат Настройки;
	
КонецФУнкции	

Процедура ОтправитьУведомление(СтрПараметрыПисьма,НастройкиОбмена)
	
	ПочтаОтправителя = Справочники.УчетныеЗаписиЭлектроннойПочты.СистемнаяУчетнаяЗаписьЭлектроннойПочты;
	
	СтруктураОшибок = СтрПараметрыПисьма.СтруктураОшибок;
	
	ТекстПисьма = 	"Контрагент: " + 	СтрПараметрыПисьма.Контрагент  +  "; " + 	СтруктураОшибок.Контрагент.message 		+ Символы.ПС +
	"Банковский счет: " + 											СтруктураОшибок.БанковскийСчет.message 	+ Символы.ПС +
	"УПД: " + 			Строка(СтрПараметрыПисьма.УПД) +  "; " +  	СтруктураОшибок.УПД.message  			+ Символы.ПС + 
	"Ссылка на документ: " +  ?(СтрПараметрыПисьма.УПД = Неопределено,"none",ПолучитьНавигационнуюСсылку(СтрПараметрыПисьма.УПД)); 
	
	ПараметрыПисьма = Новый Структура;
	ПараметрыПисьма.Вставить("Кому",НастройкиОбмена.emailУведомлений);
	ПараметрыПисьма.Вставить("УчетнаяЗапись", ПочтаОтправителя);                                                               
	ПараметрыПисьма.Вставить("Тема", "AppSell: ошибка загрузки документа в 1С");	
	ПараметрыПисьма.Вставить("Тело", ТекстПисьма);
	ПараметрыПисьма.Вставить("ТипТекста", "ПростойТекст"); 
	
	РаботаСПочтовымиСообщениями.ОтправитьПочтовоеСообщение(ПочтаОтправителя, ПараметрыПисьма);
	
КонецПроцедуры