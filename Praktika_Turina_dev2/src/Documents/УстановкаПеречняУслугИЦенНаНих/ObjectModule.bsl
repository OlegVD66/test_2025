// @strict-types

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда
#Область ОбработчикиСобытий
Процедура ОбработкаПроведения(Отказ, Режим)
	// регистр ЦеныНаДопУслуги
	Движения.ЦеныНаДопУслуги.Записывать = Истина;
	Для Каждого ТекСтрокаПлатныеУслуги Из ПлатныеУслуги Цикл
		Движение = Движения.ЦеныНаДопУслуги.Добавить();
		Движение.Период = Дата;
		Движение.Услуга = ТекСтрокаПлатныеУслуги.Услуга;
		Движение.КоличествоЗанятийВМесяц = ТекСтрокаПлатныеУслуги.КоличествоЗанятийВМесяц;
		Движение.ТарифЗаОдноЗанятие = ТекСтрокаПлатныеУслуги.ТарифЗаОдноЗанятие;
		Движение.ТарифЗаОдинМесяц = ТекСтрокаПлатныеУслуги.ТарифЗаОдинМесяц;
		Движение.ТарифЗаДОП = ТекСтрокаПлатныеУслуги.ТарифЗаДОП;
		Движение.ПродолжительностьОдногоЗанятия = ТекСтрокаПлатныеУслуги.ПродолжительностьОдногоЗанятия;
		Движение.ПериодРеализацииДОП = ТекСтрокаПлатныеУслуги.ПериодРеализацииДОП;
		Движение.КоличествоЗанятийВПериодРеализацииДОП = ТекСтрокаПлатныеУслуги.КоличествоЗанятийВПериодРеализацииДОП;
		Движение.ДополнительнаяОбщеобразовательнаяПрограмма = ТекСтрокаПлатныеУслуги.Услуга.Владелец;
		Движение.ВозрастОбучающихся = ТекСтрокаПлатныеУслуги.Услуга.ВозрастОбучающихся;
	КонецЦикла;
КонецПроцедуры
#КонецОбласти
#КонецЕсли 

