class_name OnlineClient
extends Node
## Cliente do ranking semanal (Supabase REST/RPC, via HTTPRequest). Cada chamada cria um HTTPRequest e termina em
## done(kind, ok, data). Sem OnlineConfig preenchido nada é enviado (modo offline). NÃO foi testado contra um servidor real.

signal done(kind: String, ok: bool, data: Variant)

const TIMEOUT := 8.0

func rpc(kind: String, fn: String, body: Dictionary) -> void:
    if not OnlineConfig.enabled():
        done.emit(kind, false, null)
        return
    var req := HTTPRequest.new()
    req.timeout = TIMEOUT
    add_child(req)
    req.request_completed.connect(_on_done.bind(kind, req))
    var headers := PackedStringArray(["apikey: " + OnlineConfig.ANON_KEY, "Authorization: Bearer " + OnlineConfig.ANON_KEY,
        "Content-Type: application/json"])
    var err: int = req.request(OnlineConfig.URL.rstrip("/") + "/rest/v1/rpc/" + fn, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
    if err != OK:
        req.queue_free()
        done.emit(kind, false, null)

func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, kind: String, req: HTTPRequest) -> void:
    req.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
        done.emit(kind, false, null)
        return
    var j := JSON.new()
    if j.parse(body.get_string_from_utf8()) != OK:
        done.emit(kind, false, null)
        return
    done.emit(kind, true, j.data)

func overview(pid: String) -> void:
    rpc("overview", "weekly_overview", {"p_player": pid, "p_limit": 10})

func start_attempt(pid: String, pname: String) -> void:
    rpc("attempt", "start_attempt", {"p_player": pid, "p_name": pname, "p_max": Balance.WEEKLY_MAX_ENTRIES})

func submit(pid: String, score: float) -> void:
    rpc("submit", "submit_score", {"p_player": pid, "p_score": score})
