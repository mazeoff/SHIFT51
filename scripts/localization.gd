extends Node

signal language_changed(locale: String)

const SETTINGS_PATH := "user://settings.cfg"
const SUPPORTED_LOCALES := ["ru", "en"]
const TEXT := {
	"ru": {
		"title": "SHIFT 51 — ПРОТОТИП 02", "language": "Язык", "server_address": "Адрес сервера",
		"host": "НАЧАТЬ СМЕНУ", "join": "ПОДКЛЮЧИТЬСЯ",
		"start_hint": "Запустите две копии: в одной создайте смену, во второй подключитесь.",
		"controls": "WASD — движение | Мышь — обзор | E — взаимодействие | V — сканер рядом с контейнером | Esc — мышь",
		"host_error": "Ошибка создания сервера: %s", "join_error": "Ошибка подключения: %s",
		"connecting": "Подключение…", "connection_failed": "Не удалось подключиться. Проверьте адрес и брандмауэр.",
		"order_a": "ПОРУЧЕНИЕ 51-А: доставьте синий контейнер в камеру A-17 / AMBER.",
		"perception_a": "Ваш терминал утверждает, что маркировка контейнера повреждена. За дверью 12 вы видите обычную дверь.",
		"order_b": "ПОРУЧЕНИЕ 51-Б: доставьте синий контейнер в камеру B-04 / BLUE.",
		"perception_b": "Ваш терминал предупреждает: назначение A-17 подменено. На месте двери 12 вы видите стену.",
		"verified": "ПРОВЕРЕННЫЙ ФАКТ: физическая дверь 12 существует. Состояние: %s. Общий заряд сканера израсходован.",
		"open": "ОТКРЫТА", "closed": "ЗАКРЫТА",
		"log_initial": "СИСТЕМА: авторитетное состояние двери = ЗАКРЫТА",
		"log_host": "ХОСТ: сервер слушает UDP-порт %d", "log_client": "КЛИЕНТ: подключение выполнено, идентификатор %d",
		"log_entered": "СЕРВЕР: сотрудник %d заступил на смену", "log_disconnected": "Сотрудник %d отключился.",
		"log_perception_a": "ВОСПРИЯТИЕ сотрудника %d: ДВЕРЬ / БЕЗОПАСНО", "log_perception_b": "ВОСПРИЯТИЕ сотрудника %d: СТЕНА / ОПАСНО",
		"log_out_of_range": "СЕРВЕР: сотрудник %d попытался использовать дверь издалека",
		"log_door": "СЕРВЕР: дверь 12 — %s; действие сотрудника %d",
		"log_charge_spent": "СКАНЕР: общий заряд проверки уже израсходован",
		"log_scanner_far": "СКАНЕР: сотрудник %d находится слишком далеко от двери 12",
		"log_verified": "СКАНЕР: сотрудник %d установил общий факт о контейнере",
		"prompt_door": "[E] Использовать дверь 12", "prompt_container": "[E] Взять контейнер",
		"prompt_chamber_a": "Камера A-17", "prompt_chamber_b": "Камера B-04",
		"prompt_deposit_a": "[E] Поместить контейнер в A-17", "prompt_deposit_b": "[E] Поместить контейнер в B-04",
		"prompt_elevator": "[E] Завершить смену в лифте",
		"verified_container": "ПРОВЕРЕННЫЙ ФАКТ: физическая метка — BLUE / B-04. Общий заряд сканера израсходован.",
		"task_success": "СОДЕРЖАНИЕ СТАБИЛЬНО: контейнер принят камерой B-04.",
		"task_failure": "НАРУШЕНИЕ СОДЕРЖАНИЯ: камера A-17 отвергла контейнер. Питание повреждено.",
		"return_to_elevator": "Основная задача завершена. Вернитесь к лифту у начала коридора.",
		"result_success": "СМЕНА ЗАВЕРШЕНА\nКонтейнер размещён правильно.\nРеальность стабильна.",
		"result_failure": "СМЕНА ЗАВЕРШЕНА С НАРУШЕНИЕМ\nКонтейнер размещён неверно.\nКомплекс остаётся нестабилен.",
		"success": "УСПЕХ", "failure": "НАРУШЕНИЕ",
		"log_pickup": "СЕРВЕР: сотрудник %d взял контейнер",
		"log_task_result": "СЕРВЕР: сотрудник %d завершил содержание — %s",
		"log_power_failure": "КОМПЛЕКС: ошибка содержания вызвала аварийное отключение питания",
		"log_elevator_locked": "ЛИФТ: сначала завершите основную задачу"
	},
	"en": {
		"title": "SHIFT 51 — PROTOTYPE 02", "language": "Language", "server_address": "Server address",
		"host": "HOST SHIFT", "join": "JOIN SHIFT", "start_hint": "Start two copies: host in one, join in another.",
		"controls": "WASD — move | Mouse — look | E — interact | V — scan near container | Esc — release mouse",
		"host_error": "Host error: %s", "join_error": "Join error: %s", "connecting": "Connecting…",
		"connection_failed": "Connection failed. Check address and firewall.",
		"order_a": "WORK ORDER 51-A: Deliver the blue container to bay A-17 / AMBER.",
		"perception_a": "Your terminal claims the container label is damaged. Door 12 appears to be a normal door.",
		"order_b": "WORK ORDER 51-B: Deliver the blue container to bay B-04 / BLUE.",
		"perception_b": "Your terminal warns that destination A-17 was substituted. Door 12 appears as a wall.",
		"verified": "VERIFIED EVIDENCE: physical Door 12 exists. Current state: %s. Shared scanner charge depleted.",
		"open": "OPEN", "closed": "CLOSED", "log_initial": "SYSTEM: authoritative door state = CLOSED",
		"log_host": "HOST: listening on UDP %d", "log_client": "CLIENT: connected as peer %d",
		"log_entered": "AUTHORITY: employee %d entered the shift", "log_disconnected": "Employee %d disconnected.",
		"log_perception_a": "PERCEPTION employee %d: DOOR / SAFE", "log_perception_b": "PERCEPTION employee %d: WALL / UNSAFE",
		"log_out_of_range": "AUTHORITY: employee %d attempted door interaction out of range",
		"log_door": "AUTHORITY: Door 12 = %s, changed by employee %d",
		"log_charge_spent": "SCANNER: shared verification charge already spent",
		"log_scanner_far": "SCANNER: employee %d is too far from Door 12",
		"log_verified": "SCANNER: employee %d established a shared fact about the container",
		"prompt_door": "[E] Operate Door 12", "prompt_container": "[E] Pick up container",
		"prompt_chamber_a": "Bay A-17", "prompt_chamber_b": "Bay B-04",
		"prompt_deposit_a": "[E] Deposit container in A-17", "prompt_deposit_b": "[E] Deposit container in B-04",
		"prompt_elevator": "[E] End shift at elevator",
		"verified_container": "VERIFIED FACT: physical tag reads BLUE / B-04. Shared scanner charge depleted.",
		"task_success": "CONTAINMENT STABLE: container accepted by bay B-04.",
		"task_failure": "CONTAINMENT BREACH: bay A-17 rejected the container. Power system damaged.",
		"return_to_elevator": "Primary task resolved. Return to the elevator at the start of the corridor.",
		"result_success": "SHIFT COMPLETE\nContainer placed correctly.\nReality remains stable.",
		"result_failure": "SHIFT COMPLETE WITH BREACH\nContainer placed incorrectly.\nFacility remains unstable.",
		"success": "SUCCESS", "failure": "BREACH",
		"log_pickup": "AUTHORITY: employee %d picked up the container",
		"log_task_result": "AUTHORITY: employee %d resolved containment — %s",
		"log_power_failure": "FACILITY: containment error triggered emergency power loss",
		"log_elevator_locked": "ELEVATOR: resolve the primary task first"
	}
}

var locale := "ru"

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		var saved_locale: String = config.get_value("interface", "language", "ru")
		if saved_locale in SUPPORTED_LOCALES:
			locale = saved_locale

func set_locale(new_locale: String) -> void:
	if new_locale not in SUPPORTED_LOCALES or new_locale == locale:
		return
	locale = new_locale
	var config := ConfigFile.new()
	config.set_value("interface", "language", locale)
	config.save(SETTINGS_PATH)
	language_changed.emit(locale)

func text(key: String, values: Array = []) -> String:
	var translated: String = TEXT.get(locale, TEXT["ru"]).get(key, key)
	return translated % values if not values.is_empty() else translated
