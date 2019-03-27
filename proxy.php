<?php
$url=$_POST["url"];
if(startsWith($url,"http://osc-internal.gsc.riken.jp/~ah3q")){
  $context=stream_context_create(array('http'=>array('header'=>"Authorization: Basic ".base64_encode("ah3q:has_q3ha"))));
  echo file_get_contents(htmlspecialchars($url),false,$context);
}else{
  echo file_get_contents($url);
}
function startsWith($haystack,$needle){return (strpos($haystack,$needle)===0);}
?>
