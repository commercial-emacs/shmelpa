<?php

function live_curl($url, $filename) {
    $ch = curl_init($url);
    $fp = fopen($filename, 'w');
    curl_setopt($ch, CURLOPT_FILE, $fp);
    curl_setopt($ch, CURLOPT_FAILONERROR, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_exec($ch);
    fclose($fp);
    return $ch;
}

# $nominal_target = basename($_SERVER['REQUEST_URI']);
# list($nominal_suffix, $package_name) = array_map("strrev", explode("-", strrev($nominal_target), 2));
# list($suffix) = array_map("strrev", explode(strrev("snapshot"), strrev($nominal_suffix), 2));
# $target = implode("-", [$package_name, $suffix]);

$target = basename($_SERVER['REQUEST_URI']);
list(, $package_name) = array_map("strrev", explode("-", strrev($target), 2));
$cache = dirname($_SERVER['DOCUMENT_ROOT']) . "/tmp/targets";
if (!is_dir($cache)) {
    if (!mkdir($cache, 0755, true)) {
        header("Content-Type: text/plain");
        echo "$cache\n";
        echo error_get_last()['message'];
        exit();
    }
}
$readme = "$cache/${package_name}-readme.txt";
if (!file_exists($readme)) {
    curl_close(live_curl("https://melpa.org/packages/${package_name}-readme.txt", $readme));
}
$filename = "$cache/$target";
$filesize = file_exists($filename) ? filesize($filename) : 0;
if (!$filesize) {
    array_map('unlink',
              array_filter((array)glob("$cache/${package_name}-[0-9][0-9][0-9][0-9][0-9][0-9][0-9]*")));
    $ch = live_curl("https://melpa.org/packages/${target}", $filename);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    if ($status >= 400 || curl_error($ch)) {
        unlink($filename);
        header("HTTP/1.0 " . $status . " " . curl_errno($ch));
        exit();
    }
    curl_close($ch);
    $filesize = file_exists($filename) ? filesize($filename) : 0;
}
header("Content-Type: " . pathinfo($filename, PATHINFO_EXTENSION) == "tar" ? "application/octet-stream" : "text/plain");
header("Content-Length: " . $filesize);
echo file_get_contents($filename)

?>
