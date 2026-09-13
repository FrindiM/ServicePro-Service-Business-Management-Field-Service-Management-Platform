<?php
return [
  'name' => \App\Core\Env::get('APP_NAME','ServicePro'),
  'env' => \App\Core\Env::get('APP_ENV','production'),
  'url' => rtrim(\App\Core\Env::get('APP_URL','http://localhost'),'/'),
  'timezone' => \App\Core\Env::get('APP_TIMEZONE','Asia/Makassar'),
];
