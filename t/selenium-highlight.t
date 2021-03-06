use lib '.';
use t::Selenium;

my $t          = t::Selenium->selenium_init('Convos', {lazy => 1, login => 1});
my $user       = $t->app->core->get_user("$NICK\@convos.by");
my $connection = $user->get_connection('irc-default');

$connection->_event_privmsg(
  {
    event  => 'privmsg',
    prefix => 'batgirl!batgirl@i.love.debian.org',
    params => [$NICK, 'What about a normal message in a channel?'],
  }
);

$t->wait_until(sub { $_->find_element('.convos-main-menu [href="#chat/irc-default/batgirl"]') });
$t->live_element_exists_not('.convos-main-menu [href="#chat/irc-default/batgirl"] .n-unread');
$t->click_ok('.convos-main-menu [href="#chat/irc-default/#test"]');

$connection->_fallback(
  {
    command  => '266',
    event    => 'RPL_GLOBALUSERS',
    params   => [$NICK, 'Current global users: 23  Max: 82'],
    prefix   => 'hybrid8.debian.local',
    raw_line => ":hybrid8.debian.local 266 $NICK :Current global users: 23  Max: 82"
  }
);

$connection->_event_privmsg(
  {
    event  => 'privmsg',
    prefix => 'batgirl!batgirl@i.love.debian.org',
    params => [$NICK, 'What about a normal message in a channel?'],
  }
);

$t->wait_until(
  sub { $_->find_element('.convos-main-menu [href="#chat/irc-default/batgirl"] .n-unread') });
$t->live_text_is('.convos-main-menu [href="#chat/irc-default/batgirl"] .n-unread', '1');

$connection->_event_privmsg(
  {
    event  => 'privmsg',
    prefix => 'batgirl!batgirl@i.love.debian.org',
    params => [$NICK, "What if you are mentioned $NICK?"],
  }
);

$t->wait_until(sub { $_->find_element('.convos-header-links .n-notifications') });
$t->live_text_is('.convos-main-menu [href="#chat/irc-default/batgirl"] .n-unread', '2');

$t->click_ok('.convos-main-menu [href="#chat/irc-default/batgirl"]');
$t->live_element_exists_not('.convos-main-menu [href="#chat/irc-default/batgirl"] .n-unread');

$connection->_event_privmsg(
  {
    event  => 'privmsg',
    prefix => 'batgirl!batgirl@i.love.debian.org',
    params => ["#test", 'who is strongest: supergirl or wonderwoman?'],
  }
);

$connection->_event_privmsg(
  {
    event  => 'privmsg',
    prefix => 'batgirl!batgirl@i.love.debian.org',
    params => ["#test", "Are you here $NICK?"],
  }
);

$t->live_text_is('.convos-header-links .n-notifications', '2');
$t->click_ok('[href="#notifications"]');
$t->click_ok('[href="#mark-as-read"]');
$t->live_element_exists_not('.convos-header-links .n-notifications');

# server messages should not result in notifications
is $t->driver->execute_script('return window.Notification.simple.count'), 4, 'simple.count';

done_testing;
