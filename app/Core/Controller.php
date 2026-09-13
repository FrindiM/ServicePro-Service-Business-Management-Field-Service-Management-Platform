<?php
namespace App\Core;
abstract class Controller {
    protected function view(string $view, array $data=[]): void {
        extract($data, EXTR_SKIP);
        $viewFile = BASE_PATH.'/app/Views/'.$view.'.php';
        if (!is_file($viewFile)) throw new \RuntimeException("View not found: {$view}");
        ob_start(); require $viewFile; $content = ob_get_clean();
        require BASE_PATH.'/app/Views/layouts/app.php';
    }
    protected function requireCsrf(): void {
        if (!Csrf::verify($_POST['_token'] ?? $_SERVER['HTTP_X_CSRF_TOKEN'] ?? null)) {
            if (Request::wantsJson()) Response::json(['success'=>false,'message'=>'Invalid CSRF token.','errors'=>[]],419);
            http_response_code(419); exit('Invalid CSRF token');
        }
    }
}
