<?php
namespace App\Core;
final class Router {
    private array $routes=[];
    public function get(string $path, array|callable $handler, array $middleware=[]): void { $this->add('GET',$path,$handler,$middleware); }
    public function post(string $path, array|callable $handler, array $middleware=[]): void { $this->add('POST',$path,$handler,$middleware); }
    private function add(string $method,string $path,array|callable $handler,array $middleware): void {
        $this->routes[] = compact('method','path','handler','middleware');
    }
    public function dispatch(): void {
        $method = Request::method(); $path = rtrim(Request::path(),'/') ?: '/';
        foreach ($this->routes as $route) {
            $regex = '#^'.preg_replace('#\{([a-zA-Z_][a-zA-Z0-9_]*)\}#','(?P<$1>[^/]+)', rtrim($route['path'],'/') ?: '/').'$#';
            if ($route['method'] !== $method || !preg_match($regex,$path,$m)) continue;
            foreach ($route['middleware'] as $mw) $mw::handle();
            $params = array_filter($m,'is_string',ARRAY_FILTER_USE_KEY);
            if (is_callable($route['handler'])) { ($route['handler'])(...array_values($params)); return; }
            [$class,$action] = $route['handler']; (new $class())->$action(...array_values($params)); return;
        }
        http_response_code(404); require BASE_PATH.'/app/Views/errors/404.php';
    }
}
