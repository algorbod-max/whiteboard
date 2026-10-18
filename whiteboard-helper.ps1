# Whiteboard helper.
# Serves the whiteboard at http://localhost:8790/ (only to this computer), saves lesson pictures
# into the Sessions folder, then opens the whiteboard window. Stops by itself 30 minutes after
# the whiteboard window is closed. Uses only what comes with Windows.
param([int]$Port = 8790, [switch]$NoBrowser)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sessions = Join-Path $root 'Sessions'
$url = "http://localhost:$Port/whiteboard.html"

function Open-Board {
    if ($NoBrowser) { return }
    $edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($edge) { Start-Process $edge -ArgumentList "--app=$url", '--start-maximized' } else { Start-Process $url }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try { $listener.Start() } catch { Open-Board; exit 0 }   # already running: just open the window
Open-Board

# Handwriting: Windows' own ink recogniser (offline)
$recognizer = $null
try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    Add-Type -AssemblyName System.Web.Extensions
    $null = [Windows.UI.Input.Inking.InkStrokeContainer, Windows.UI.Input.Inking, ContentType = WindowsRuntime]
    $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    $asTaskResults = $asTask.MakeGenericMethod([System.Collections.Generic.IReadOnlyList[Windows.UI.Input.Inking.InkRecognitionResult]])
    $recognizer = New-Object Windows.UI.Input.Inking.InkRecognizerContainer
    $all = $recognizer.GetRecognizers()
    $english = @($all | Where-Object { $_.Name -like '*English (US)*' }) + @($all | Where-Object { $_.Name -like '*English*' }) | Select-Object -First 1
    if ($english) { $recognizer.SetDefaultRecognizer($english) }
} catch { $recognizer = $null }
$json = New-Object System.Web.Script.Serialization.JavaScriptSerializer

function Read-Handwriting($strokes) {
    $sc = New-Object Windows.UI.Input.Inking.InkStrokeContainer
    $sb = New-Object Windows.UI.Input.Inking.InkStrokeBuilder
    foreach ($s in $strokes) {
        $pts = New-Object 'System.Collections.Generic.List[Windows.Foundation.Point]'
        foreach ($p in $s) { $pts.Add((New-Object Windows.Foundation.Point([double]$p[0], [double]$p[1]))) }
        if ($pts.Count -eq 1) { $pts.Add((New-Object Windows.Foundation.Point(([double]$s[0][0] + 1), [double]$s[0][1]))) }
        if ($pts.Count -ge 2) { $sc.AddStroke($sb.CreateStroke($pts)) }
    }
    $task = $asTaskResults.Invoke($null, @($recognizer.RecognizeAsync($sc, [Windows.UI.Input.Inking.InkRecognitionTarget]::All)))
    if (-not $task.Wait(8000)) { return @() }
    $words = New-Object System.Collections.ArrayList
    foreach ($r in $task.Result) { [void]$words.Add([string[]]@($r.GetTextCandidates() | Select-Object -First 4)) }
    return , $words.ToArray()
}

$types = @{ '.html' = 'text/html; charset=utf-8'; '.png' = 'image/png'; '.ico' = 'image/x-icon'; '.js' = 'text/javascript'; '.css' = 'text/css' }
$lastHit = Get-Date

function Send($res, [int]$code, [string]$type, [byte[]]$bytes) {
    $res.StatusCode = $code
    $res.ContentType = $type
    $res.Headers['Cache-Control'] = 'no-store'
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.Close()
}
function SendText($res, [int]$code, [string]$type, [string]$text) { Send $res $code $type ([Text.Encoding]::UTF8.GetBytes($text)) }
function Clean([string]$s) { if (-not $s) { return '' }; return (($s -replace '[^A-Za-z0-9 ._-]', '') -replace '\.{2,}', '.').Trim(' .') }

while ($listener.IsListening) {
    $wait = $listener.GetContextAsync()
    while (-not $wait.Wait(60000)) {
        if (((Get-Date) - $lastHit).TotalMinutes -gt 30) { $listener.Stop(); exit 0 }
    }
    $ctx = $wait.Result; $req = $ctx.Request; $res = $ctx.Response; $lastHit = Get-Date
    try {
        $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
        if ($req.HttpMethod -eq 'POST' -and $path -eq '/save') {
            $folder = Clean $req.QueryString['folder']; if (-not $folder) { $folder = 'Other' }
            $name = Clean $req.QueryString['name']
            if ($name -notmatch '\.png$') { throw 'bad file name' }
            $dir = Join-Path $sessions $folder
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            $file = Join-Path $dir $name
            $n = 2
            while (Test-Path -LiteralPath $file) { $file = Join-Path $dir ($name -replace '\.png$', " ($n).png"); $n++ }
            $fs = [IO.File]::Create($file)
            try { $req.InputStream.CopyTo($fs) } finally { $fs.Close() }
            $json = '{"ok":true,"folder":"' + $folder + '","name":"' + (Split-Path -Leaf $file) + '"}'
            SendText $res 200 'application/json' $json
        }
        elseif ($req.HttpMethod -eq 'POST' -and $path -eq '/recognize') {
            if (-not $recognizer) { SendText $res 503 'text/plain' 'no handwriting recogniser'; continue }
            $reader = New-Object IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)
            $body = $json.DeserializeObject($reader.ReadToEnd()); $reader.Close()
            $words = Read-Handwriting $body['strokes']
            SendText $res 200 'application/json' ($json.Serialize(@{ words = $words }))
        }
        elseif ($path -eq '/ping') { SendText $res 200 'text/plain' 'ok' }
        elseif ($path -eq '/open') {
            $folder = Clean $req.QueryString['folder']
            $dir = if ($folder) { Join-Path $sessions $folder } else { $sessions }
            if (Test-Path -LiteralPath $dir) { Start-Process explorer.exe -ArgumentList "`"$dir`"" }
            SendText $res 200 'text/plain' 'ok'
        }
        else {
            $rel = $path.TrimStart('/'); if (-not $rel) { $rel = 'whiteboard.html' }
            $file = Join-Path $root $rel
            $ext = [IO.Path]::GetExtension($rel).ToLower()
            if ($rel -match '[\\/:]' -or $rel -match '\.\.' -or -not $types.ContainsKey($ext) -or -not (Test-Path -LiteralPath $file)) {
                SendText $res 404 'text/plain' 'not found'
            } else {
                Send $res 200 $types[$ext] ([IO.File]::ReadAllBytes($file))
            }
        }
    } catch {
        try { SendText $res 500 'text/plain' $_.Exception.Message } catch {}
    }
}
