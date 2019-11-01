# Requires Powershell 7.0+

$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"

class Engine {
    [String] $Name
    [String] $BaseUrl

    Engine ([String] $Name, [String] $BaseUrl)
    {
        $this.Name = $Name
        $this.BaseUrl = $BaseUrl
    }

    [String] GetUrl($Query)
    {
       return $this.BaseUrl -Replace "<query>", $Query
    }
}

$engines = @(
    # [Engine]::New("google-html", "https://www.google.com/search?q=<query>&gbv=1&start=0&sa=N"),
    [Engine]::New("google", "https://www.google.com/search?q=<query>"),
    [Engine]::New("startpage", "https://www.startpage.com/do/search?q=<query>"),
    [Engine]::New("ddg", "https://duckduckgo.com/?q=<query>"),
    [Engine]::New("ddg-html", "https://duckduckgo.com/html/?q=<query>"), 
    [Engine]::New("qwant", "https://www.qwant.com/?q=<query>&t=web"), 
    [Engine]::New("bing", "https://www.bing.com/search?q=<query>") 

)
$terms = @("coffee", "abc", "adelle", "world war 2", "aspirin", "shanghai")

$results = @()
$engines | ForEach-Object { 
    $eng = $_; 
    # $total_seconds = 0.0
    $secondsBag = [System.Collections.Concurrent.ConcurrentBag[float]]::new()
    $secondsBag.Add(0)

    $terms | ForEach-Object -Parallel { 
        $term = $_; 
        echo "Testing engine '$($using:eng.Name)' with query '$term'"
        $bag = $using:secondsBag
        $url = ($using:eng).GetUrl($term)
        $seconds = (Measure-Command { curl -s -A $using:userAgent $url }).TotalSeconds
        $r = $bag.TryAdd($seconds)
    } -ThrottleLimit 5
    
    $total_seconds = ($secondsBag | Measure-Object -Sum).Sum

    $o = New-Object psobject
    $o | Add-Member -MemberType NoteProperty -Name "Engine" -Value $eng.Name
    $o | Add-Member -MemberType NoteProperty -Name "Avg Secs" -Value $([math]::Round($total_seconds / $terms.Length, 3))
    $results += $o
}

$results | Sort-Object -Property "Avg Secs"
