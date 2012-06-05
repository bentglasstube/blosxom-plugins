<?php
	function smarty_modifier_encode_ampersands($text) {
	  return preg_replace("/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w{1,8});)/i","&amp;",$text);
	}
?>