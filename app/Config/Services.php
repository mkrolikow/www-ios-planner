public static function jwt($getShared = true)
{
    if ($getShared) {
        return static::getSharedInstance('jwt');
    }
    return new \App\Libraries\JwtService(config('Jwt'));
}
