package Convos::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

use Convos::Util 'E';

sub delete {
  my $self = shift->openapi->valid_input or return;
  my $user = $self->backend->user        or return $self->unauthorized;

  if (@{$self->app->core->users} <= 1) {
    return $self->render(openapi => E('You are the only user left.'), status => 400);
  }

  $self->delay(
    sub { $self->app->core->backend->delete_object($user, shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      delete $self->session->{email};
      $self->render(openapi => {message => 'You have been erased.'});
    },
  );
}

sub generate_recover_url {
  my $self  = shift;
  my $email = $self->stash('email');
  my $exp   = time - int(rand 3600) + 3600 * 12 + 1800;
  my $check = Mojo::Util::hmac_sha1_sum("$email/$exp", $self->app->secrets->[0]);

  $self->render(text => $self->url_for(recover => {check => $check, exp => $exp}));
}

sub get {
  my $self = shift->openapi->valid_input or return;
  my $user = $self->backend->user        or return $self->unauthorized;

  $self->delay(
    sub { $user->get($self->req->url->query->to_hash, shift->begin); },
    sub {
      my ($delay, $err, $res) = @_;
      die $err if $err;
      $self->render(openapi => $res);
    }
  );
}

sub login {
  my $self = shift->openapi->valid_input or return;

  $self->delay(
    sub { $self->auth->login($self->req->json, shift->begin) },
    sub {
      my ($delay, $err, $user) = @_;
      return $self->render(openapi => E($err), status => 400) if $err;
      return $self->session(email => $user->email)->render(openapi => $user);
    },
  );
}

sub logout {
  my $self = shift;

  $self->delay(
    sub { $self->auth->logout({}, shift->begin) },
    sub {
      my ($delay, $err) = @_;
      return $self->render(openapi => E($err), status => 400) if $err;
      return $self->session({expires => 1})->redirect_to('index');
    },
  );
}

sub recover {
  my $self  = shift;
  my $email = $self->stash('email');
  my $exp   = $self->stash('exp');
  my $redirect_url;

  # expired
  return $self->render(status => 410) if $exp < time;

  for my $secret (@{$self->app->secrets}) {
    my $check = Mojo::Util::hmac_sha1_sum("$email/$exp", $secret);
    next if $check ne $self->stash('check');
    $redirect_url = $self->url_for('index');
    last;
  }

  return $self->render(status => 400) unless $redirect_url;

  $redirect_url->query->param(recover => 1);
  $self->session(email => $email)->redirect_to($redirect_url);
}

sub register {
  my $self = shift->openapi->valid_input or return;

  $self->delay(
    sub { $self->auth->register($self->req->json, shift->begin) },
    sub {
      my ($delay, $err, $user) = @_;
      return $self->render(openapi => E($err), status => 400) if $err;
      return $self->session(email => $user->email)->render(openapi => $user);
    },
  );
}

sub update {
  my $self = shift->openapi->valid_input or return;
  my $json = $self->req->json;
  my $user = $self->backend->user or return $self->unauthorized;

  # TODO: Add support for changing email

  unless (%$json) {
    return $self->render(openapi => $user);
  }

  $self->delay(
    sub {
      my ($delay) = @_;
      $user->highlight_keywords($json->{highlight_keywords}) if $json->{highlight_keywords};
      $user->set_password($json->{password})                 if $json->{password};
      $user->save($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $self->render(openapi => $user);
    },
  );
}

1;

=encoding utf8

=head1 NAME

Convos::Controller::User - Convos user actions

=head1 DESCRIPTION

L<Convos::Controller::User> is a L<Mojolicious::Controller> with
user related actions.

=head1 METHODS

=head2 delete

See L<Convos::Manual::API/deleteUser>.

=head2 generate_recover_url

Used to generate a URL suitable for L</recover>.

=head2 get

See L<Convos::Manual::API/getUser>.

=head2 login

See L<Convos::Manual::API/loginUser>.

=head2 logout

See L<Convos::Manual::API/logoutUser>.

=head2 recover

Used to validate a recover URL, with email, expiration date and a checksum.

=head2 related

=head2 register

See L<Convos::Manual::API/registerUser>.

=head2 update

See L<Convos::Manual::API/updateUser>.

=head1 SEE ALSO

L<Convos>.

=cut
