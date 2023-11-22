﻿#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда
	
Функция ЗначениеНастройки(Знач Настройка) Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ ПЕРВЫЕ 1
	               |	ИсточникДанных.Значение КАК Значение
	               |ИЗ
	               |	РегистрСведений.бит_ЗначенияНастроек КАК ИсточникДанных
	               |ГДЕ
	               |	ИсточникДанных.Настройка = &Настройка";
	Запрос.УстановитьПараметр("Настройка", Настройка);
	УстановитьПривилегированныйРежим(Истина);
	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда
		Значение = Выборка.Значение;
	Иначе
		Значение = Неопределено;
	КонецЕсли;
	УстановитьПривилегированныйРежим(Ложь);
	
	Возврат Значение;
	
КонецФункции

Процедура ЗаписатьЗначениеНастройки(ДанныеЗаполнения) Экспорт
	МенеджерЗаписи = РегистрыСведений.бит_ЗначенияНастроек.СоздатьМенеджерЗаписи();
	ЗаполнитьЗначенияСвойств(МенеджерЗаписи,ДанныеЗаполнения);
	МенеджерЗаписи.Записать(Истина);
КонецПроцедуры


#КонецЕсли