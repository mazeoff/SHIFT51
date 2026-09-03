extends Node

signal language_changed(locale: String)

const SETTINGS_PATH := "user://settings.cfg"
const SUPPORTED_LOCALES := ["ru", "en"]
const TEXT := {
	"ru": {
		"title": "SHIFT 51 — ПРОТОТИП 01", "language": "Язык", "server_address": "Адрес сервера",
		"host": "НАЧАТЬ СМЕНУ", "join": "ПОДКЛЮЧИТЬСЯ",
		"start_hint": "Запустите две копии: в одной создайте смену, во второй подключитесь.",
		"controls": "WASD — движение | Мышь — обзор | E — дверь | V — проверка (один общий заряд) | Esc — освободить мышь",
		"host_error": "Ошибка создания сервера: %s", "join_error": "Ошибка подключения: %s",
		"connecting": "Подключение…", "connection_failed": "Не удалось подключиться. Проверьте адрес и брандмауэр.",
		"order_a": "РАБОЧЕЕ ПОРУЧЕНИЕ 51-А: откройте дверь 12 и осмотрите камеру.",
		"perception_a": "Локальное восприятие: усиленная служебная дверь. Терминал помечает маршрут как БЕЗОПАСНЫЙ.",
		"order_b": "УВЕДОМЛЕНИЕ О СОДЕРЖАНИИ 51-Б: дверь 12 была замурована. Не нарушайте целостность стены.",
		"perception_b": "Локальное восприятие: сплошная бетонная стена. Терминал помечает маршрут как ОПАСНЫЙ.",
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
		"log_verified": "СКАНЕР: сотрудник %d установил общий факт — дверь 12 физически существует"
	},
	"en": {
		"title": "SHIFT 51 — PROTOTYPE 01", "language": "Language", "server_address": "Server address",
		"host": "HOST SHIFT", "join": "JOIN SHIFT", "start_hint": "Start two copies: host in one, join in another.",
		"controls": "WASD — move | Mouse — look | E — door | V — verify (one shared charge) | Esc — release mouse",
		"host_error": "Host error: %s", "join_error": "Join error: %s", "connecting": "Connecting…",
		"connection_failed": "Connection failed. Check address and firewall.",
		"order_a": "WORK ORDER 51-A: Open Door 12 and inspect the chamber.",
		"perception_a": "Local perception: reinforced service door. Your terminal marks the route SAFE.",
		"order_b": "CONTAINMENT NOTICE 51-B: Door 12 was sealed. Do not breach the wall.",
		"perception_b": "Local perception: continuous concrete wall. Your terminal marks the route UNSAFE.",
		"verified": "VERIFIED EVIDENCE: physical Door 12 exists. Current state: %s. Shared scanner charge depleted.",
		"open": "OPEN", "closed": "CLOSED", "log_initial": "SYSTEM: authoritative door state = CLOSED",
		"log_host": "HOST: listening on UDP %d", "log_client": "CLIENT: connected as peer %d",
		"log_entered": "AUTHORITY: employee %d entered the shift", "log_disconnected": "Employee %d disconnected.",
		"log_perception_a": "PERCEPTION employee %d: DOOR / SAFE", "log_perception_b": "PERCEPTION employee %d: WALL / UNSAFE",
		"log_out_of_range": "AUTHORITY: employee %d attempted door interaction out of range",
		"log_door": "AUTHORITY: Door 12 = %s, changed by employee %d",
		"log_charge_spent": "SCANNER: shared verification charge already spent",
		"log_scanner_far": "SCANNER: employee %d is too far from Door 12",
		"log_verified": "SCANNER: employee %d established a shared fact — Door 12 physically exists"
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
