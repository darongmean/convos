use lib '.';
use t::Helper;

$ENV{CONVOS_BACKEND} = 'Convos::Core::Backend';
my $t = t::Helper->t;

$t->app->core->user({email => 'superman@example.com'})->set_password('s3cret');

$t->get_ok('/api/user')->status_is(401);

$t->post_ok('/api/user/login')->status_is(400)
  ->json_is('/errors/0', {message => 'Expected object - got null.', path => '/body'});

$t->post_ok('/api/user/login', json => {email => 'xyz', password => 'foo'})->status_is(400)
  ->json_is('/errors/0', {message => 'Does not match email format.', path => '/body/email'});

$t->post_ok('/api/user/login', json => {email => 'superman@example.com'})->status_is(400)
  ->json_is('/errors/0/path', '/body/password');

$t->post_ok('/api/user/login', json => {email => 'superman@example.com', password => 'xyz'})
  ->status_is(400)->json_is('/errors/0', {message => 'Invalid email or password.', path => '/'});

$t->post_ok('/api/user/login', json => {email => 'superman@example.com', password => 's3cret'})
  ->status_is(200)->json_is('/email', 'superman@example.com')
  ->json_like('/registered', qr/^[\d-]+T[\d:]+Z$/);

$t->get_ok('/api/user')->status_is(200);

# make sure this url does not exist from web
$t->get_ok('/user/recover/superman@example.com')->status_is(404);

done_testing;
