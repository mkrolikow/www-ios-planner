$routes->group('api', ['namespace' => 'App\Controllers\Api'], function($routes) {
    $routes->post('auth/login', 'AuthController::login');
    $routes->post('auth/refresh', 'AuthController::refresh');

    $routes->group('', ['filter' => 'jwt'], function($routes) {
        $routes->get('types', 'TypesController::index');
        $routes->post('types', 'TypesController::create');
        $routes->put('types/(:num)', 'TypesController::update/$1');
        $routes->delete('types/(:num)', 'TypesController::delete/$1');

        $routes->get('events', 'EventsController::index');
        $routes->post('events', 'EventsController::create');
        $routes->put('events/(:num)', 'EventsController::update/$1');
        $routes->delete('events/(:num)', 'EventsController::delete/$1');
    });
});

// Admin (CI4 views)
$routes->group('admin', ['namespace' => 'App\Controllers\Admin'], function($routes) {
    $routes->get('login', 'AuthController::loginForm');
    $routes->post('login', 'AuthController::loginPost');
    $routes->get('logout', 'AuthController::logout');

    $routes->get('', 'DashboardController::index', ['filter' => 'adminauth']);
    $routes->get('types', 'TypesController::index', ['filter' => 'adminauth']);
    $routes->post('types/create', 'TypesController::create', ['filter' => 'adminauth']);
});
