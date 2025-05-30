// @strict-types

#Область Команды

&НаКлиенте
Процедура Сформировать(Команда)
	СформироватьПриказНаЗачисление();
КонецПроцедуры

&НаКлиенте
Процедура Заполнить(Команда)
	ЗаполнитьСписокДетейНаСервере();
КонецПроцедуры

#КонецОбласти

&НаСервере
Процедура СформироватьПриказНаЗачисление()
	
	Если ПустаяСтрока(Объект.НомерПриказа) Тогда
		Сообщение = Новый СообщениеПользователю();
		Сообщение.Текст = НСтр("ru = 'Не заполнен номер приказа'");
		Сообщение.Сообщить();
		Возврат;
	КонецЕсли;
	
	Если ПустаяСтрока(Объект.ДатаЗачисления) Тогда
		Сообщение = Новый СообщениеПользователю();
		Сообщение.Текст = НСтр("ru = 'Не заполнена дата зачисления'");
		Сообщение.Сообщить();
		Возврат;
	КонецЕсли;
	
	Если Объект.СписокДетей.Количество() = 0 Тогда
		Сообщение = Новый СообщениеПользователю();
		Сообщение.Текст = НСтр("ru = 'Заполните список детей'");
		Сообщение.Сообщить();
		Возврат;
	КонецЕсли;
	
	// Получаем список детей из табличной части
	МассивДетей = Новый Массив;
	Для Каждого СтрокаДети Из Объект.СписокДетей Цикл
		Ребенок = СтрокаДети.ФИОРебенка;
		
		// Ищем все услуги для текущего ребенка
		Запрос = Новый Запрос;
		Запрос.Текст = 
		"ВЫБРАТЬ
		|    УслугиДОППоДетям.Услуга КАК Услуга
		|ИЗ
		|    РегистрСведений.УслугиДОППоДетям КАК УслугиДОППоДетям
		|ГДЕ
		|    УслугиДОППоДетям.Ребенок = &Ребенок
		|    И УслугиДОППоДетям.Операция = &ОперацияЗачисление
		|    И УслугиДОППоДетям.Период <= &ДатаЗачисления";
		
		Запрос.УстановитьПараметр("Ребенок", Ребенок);
		Запрос.УстановитьПараметр("ОперацияЗачисление", Перечисления.ОперацииУслуг.Зачисление);
		Запрос.УстановитьПараметр("ДатаЗачисления", Объект.ДатаЗачисления);
		
		Результат = Запрос.Выполнить().Выгрузить();
		
		// Формируем структуру для ребенка
		РебенокСтруктура = Новый Структура("Ребенок, Программы");
		РебенокСтруктура.Ребенок = Ребенок;
		РебенокСтруктура.Программы = Новый Массив;
		
		// Заполняем массив программ
		Для Каждого СтрокаРезультата Из Результат Цикл
			РебенокСтруктура.Программы.Добавить(СтрокаРезультата.Услуга);
		КонецЦикла;
		
		МассивДетей.Добавить(РебенокСтруктура);
	КонецЦикла;
	
	// Формируем приказ
	Приказ = РеквизитФормыВЗначение("Объект").ПолучитьМакет("ПриказОЗачислении");
	MSWord = Неопределено;
	
	Попытка
		MSWord = Приказ.Получить();
		Документ = MSWord.Application.Documents(1);
		
		// Заменяем стандартные поля
		СписокЗамен = Новый Массив;
		СписокЗамен.Добавить("<Date>;" + Формат(ТекущаяДатаСеанса(), "ДЛФ=ДД"));
		СписокЗамен.Добавить("<Nomer>;" + Объект.НомерПриказа);
		ГодЗачисления = Год(Объект.ДатаЗачисления);
		СписокЗамен.Добавить("<OldYear>;" + Формат(ГодЗачисления, "ДФ='гггг'"));
		СписокЗамен.Добавить("<NewYear>;" + Формат(ГодЗачисления + 1, "ДФ='гггг'"));
		СписокЗамен.Добавить("<DateZach>;" + Формат(Объект.ДатаЗачисления, "ДФ='дд.ММ.гггг'"));
		
		Для Каждого Замена Из СписокЗамен Цикл
			Части = СтрРазделить(Замена, ";");
			Документ.Content.Find.Execute(Части[0], Ложь, Ложь, Ложь, Ложь, Ложь, Истина, 1, Ложь, Части[1], 2);
		КонецЦикла;
		
		// Вставляем список детей
		Попытка
			Если Документ.Bookmarks.Exists("СписокДетей") Тогда
				Диапазон = Документ.Bookmarks("СписокДетей").Range;
				Диапазон.Text = "";
				
				НомерПункта = 1;
				Для Каждого Элемент Из МассивДетей Цикл
					Ребенок = Элемент.Ребенок;
					Программы = Элемент.Программы;
					
					// Формируем текст для ребенка
					ТекстРебенка = Строка(НомерПункта) + ". " + 
					Ребенок + " " +
					Формат(Ребенок.ДатаРождения, "ДФ='дд.ММ.гггг'") + 
					" года рождения, на обучение по следующей дополнительной образовательной программе:";
					
					Диапазон.InsertAfter(ТекстРебенка);
					Диапазон.InsertParagraphAfter();
					Диапазон.Collapse(0);
					
					// Добавляем список программ
					Для Каждого Программа Из Программы Цикл
						Диапазон.InsertAfter("- «" + Программа.Владелец.Наименование + "»;");
						Диапазон.InsertParagraphAfter();
						Диапазон.Collapse(0);
					КонецЦикла;
					
					НомерПункта = НомерПункта + 1;
				КонецЦикла;
				
				Документ.Bookmarks.Add("СписокДетей", Диапазон);
			Иначе
				ТекстСообщения = НСтр("ru = 'Не найдена закладка ""%1"" в шаблоне!'");
				Сообщение = Новый СообщениеПользователю();
				Сообщение.Текст = СтрШаблон(ТекстСообщения, "СписокДетей");
				Сообщение.Сообщить();
			КонецЕсли;
		Исключение
			ТекстСообщения = НСтр("ru = 'Ошибка при вставке списка: %1.'");
			Сообщение = Новый СообщениеПользователю();
			Сообщение.Текст = СтрШаблон(ТекстСообщения, ОписаниеОшибки());
			Сообщение.Сообщить();
		КонецПопытки;
		
		MSWord.Application.Visible = Истина;
		MSWord.Activate();
		
	Исключение
		ТекстСообщения = НСтр("ru = 'Ошибка при формировании документа: %1.'");
		Сообщение = Новый СообщениеПользователю();
		Сообщение.Текст = СтрШаблон(ТекстСообщения, ОписаниеОшибки());
		Сообщение.Сообщить();
		
		Попытка
			Если MSWord <> Неопределено Тогда
				MSWord.Application.Quit();
			КонецЕсли;
		Исключение
		КонецПопытки;
	КонецПопытки;
	
КонецПроцедуры
&НаСервере
Процедура ЗаполнитьСписокДетейНаСервере()
	Объект.СписокДетей.Очистить();
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	УслугиДОППоДетям.Ребенок КАК Ребенок,
	|	УслугиДОППоДетям.Услуга.Владелец КАК Программа
	|ИЗ
	|	РегистрСведений.УслугиДОППоДетям КАК УслугиДОППоДетям
	|ГДЕ
	|	УслугиДОППоДетям.Операция = &ОперацияЗачисление
	|	И УслугиДОППоДетям.Период МЕЖДУ &НачалоПериода И &ДатаЗачисления";
	НачалоПериода = ДобавитьМесяц(Объект.ДатаЗачисления, -1);  // Первое число предыдущего месяца
	Запрос.УстановитьПараметр("ОперацияЗачисление", Перечисления.ОперацииУслуг.Зачисление);
	Запрос.УстановитьПараметр("ДатаЗачисления", Объект.ДатаЗачисления);
	Запрос.УстановитьПараметр("НачалоПериода", НачалоПериода);
	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();
	Попытка
		Результат = Запрос.Выполнить();
		Если Не Результат.Пустой() Тогда
			Выборка = Результат.Выбрать();
			Пока Выборка.Следующий() Цикл
				НовСтр = Объект.СписокДетей.Добавить();
				НовСтр.ФИОРебенка = Выборка.Ребенок;
				НовСтр.ДОП = Выборка.Программа;
			КонецЦикла;
			Объект.СписокДетей.Сортировать("ФИОРебенка");
		Иначе
			Сообщение = Новый СообщениеПользователю();
			Сообщение.Текст = НСтр("ru = 'Детей для зачисления не обнаружено.'");
			Сообщение.Сообщить();    
		КонецЕсли;
	Исключение
		Сообщить("Ошибка выполнения запроса: " + ОписаниеОшибки());
		Возврат;
	КонецПопытки;
КонецПроцедуры

&НаСервереБезКонтекста
Функция ПолучитьДатуРожденияНаСервере(Знач ФИОРеб)
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	|	Дети.ДатаРождения КАК ДатаРождения
	|ИЗ
	|	Справочник.Дети КАК Дети
	|ГДЕ
	|	Дети.Ссылка = &ФИОРебенка";
	
	Запрос.УстановитьПараметр("ФИОРебенка", ФИОРеб);
	
	Результат = Запрос.Выполнить();
	
	Если Результат.Пустой() Тогда
		Возврат Неопределено;
	Иначе
		Выборка = Результат.Выбрать();
		Выборка.Следующий();
		Возврат Выборка.ДатаРождения;
	КонецЕсли;
КонецФункции 

#Область ПечатьКлиентСервер
&НаКлиенте
Процедура СформироватьКлиентСервер(Команда)	
	ОповещениеКаталог = Новый ОписаниеОповещения("СформироватьКлиентСерверПродолжение", ЭтотОбъект);
	НачатьПолучениеКаталогаВременныхФайлов(ОповещениеКаталог);
КонецПроцедуры

&НаКлиенте
Процедура СформироватьКлиентСерверПродолжение(Результат, Параметры) Экспорт	
	// Проверка заполнения обязательных полей
	Если ПустаяСтрока(Объект.НомерПриказа) Тогда
		Сообщить("Не заполнен номер приказа");
		Возврат;
	КонецЕсли;
	
	Если ПустаяСтрока(Объект.ДатаЗачисления) Тогда
		Сообщить("Не заполнена дата зачисления");
		Возврат;
	КонецЕсли;
	
	Если Объект.СписокДетей.Количество() = 0 Тогда
		Сообщить("Заполните список детей");
		Возврат;
	КонецЕсли;
	
	ИмяМакета = "ПриказОЗачисленииДД"; 
	Каталог = Результат;
	Каталог = ?(Прав(Каталог,1) = "\", Каталог, Каталог+"\");
	ПолноеИмяФайла = Каталог+"Приказ о зачислении_"+Объект.НомерПриказа+".docx";
	
	Попытка
		АдресХранилища = ПолучитьМакетСКлиентаНаСервере(ИмяМакета);
		МакетПриказаОЗачисленииДД = ПолучитьИзВременногоХранилища(АдресХранилища);
		МакетПриказаОЗачисленииДД.Записать(ПолноеИмяФайла);
	Исключение
		Сообщить(ОписаниеОшибки());
		Возврат;
	КонецПопытки;
	
	Попытка
		MSWord = Новый COMОбъект("Word.Application");
		Документ = MSWord.Documents.Open(ПолноеИмяФайла); 
	Исключение
		Сообщить("Ошибка при открытии Word: " + ОписаниеОшибки());
		Возврат;
	КонецПопытки;
	
	// Замена стандартных полей
	СписокЗамен = Новый Массив;
	СписокЗамен.Добавить("<Date>;" + Формат(ТекущаяДата(), "ДЛФ=ДД"));
	СписокЗамен.Добавить("<Nomer>;" + Объект.НомерПриказа);
	ГодЗачисления = Год(Объект.ДатаЗачисления);
	СписокЗамен.Добавить("<OldYear>;" + Формат(ГодЗачисления, "ДФ='гггг'"));
	СписокЗамен.Добавить("<NewYear>;" + Формат(ГодЗачисления + 1, "ДФ='гггг'"));
	СписокЗамен.Добавить("<DateZach>;" + Формат(Объект.ДатаЗачисления, "ДФ='дд.ММ.гггг'"));
	
	Для Каждого СтрокаЗамены Из СписокЗамен Цикл
		Части = СтрРазделить(СтрокаЗамены, ";");
		Документ.Content.Find.Execute(Части[0], Ложь, Истина, Ложь,,, Истина,, Ложь, Части[1], 2);
	КонецЦикла;
	
	// Вставка списка детей с программами
	Если Документ.Bookmarks.Exists("СписокДетей") Тогда
		Диапазон = Документ.Bookmarks("СписокДетей").Range;
		Диапазон.Text = "";
		
		НомерПункта = 1;
		ТекущийРебенок = Неопределено;
		
		Для Каждого СтрокаДети Из Объект.СписокДетей Цикл
			Если ТекущийРебенок <> СтрокаДети.ФИОРебенка Тогда
				
				ТекущийРебенок = СтрокаДети.ФИОРебенка;
				
				ТекстРебенка = Строка(НомерПункта) + ". " + 
				ТекущийРебенок + " " +
				Формат(ПолучитьДатуРожденияНаСервере(СтрокаДети.ФИОРебенка), "ДФ='дд.ММ.гггг'") + 
				" года рождения, на обучение по следующей дополнительной образовательной программе:";
				
				Диапазон.InsertAfter(ТекстРебенка);
				Диапазон.InsertParagraphAfter();
				Диапазон.Collapse(0);
				
				НомерПункта = НомерПункта + 1;
			КонецЕсли;
			
			// Добавляем программу
			Диапазон.InsertAfter("- «" + СтрокаДети.ДОП + "»;");
			Диапазон.InsertParagraphAfter();
			Диапазон.Collapse(0);
		КонецЦикла;
		
		Документ.Bookmarks.Add("СписокДетей", Диапазон);
	Иначе
		Сообщить("Не найдена закладка 'СписокДетей' в шаблоне!");
	КонецЕсли;
	
	// Показываем результат
	MSWord.Application.Visible = Истина;
	Документ.Activate();
КонецПроцедуры
//получаем макет на сервере и передаем на клиента через хранилище
&НаСервереБезКонтекста
Функция ПолучитьМакетСКлиентаНаСервере(ИмяМакета)
	Возврат ПоместитьВоВременноеХранилище(Документы.ПриказОЗачислении.ПолучитьМакет(ИмяМакета));
КонецФункции
#КонецОбласти