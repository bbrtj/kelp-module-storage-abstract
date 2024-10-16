package Kelp::Module::Storage::Abstract;

use Kelp::Base 'Kelp::Module';
use Storage::Abstract;
use Plack::App::Storage::Abstract;

sub build
{
	my ($self, %args) = @_;
	my $app = $self->app;

	my $routes = delete $args{public_routes} // {};
	require Kelp::Module::Storage::Abstract::KelpExtensions
		if delete $args{kelp_extensions};

	my $storage = Storage::Abstract->new(%args);

	foreach my $key (keys %$routes) {
		my $mapping = $routes->{$key};
		my $this_storage = $storage;

		# key will have />file appended
		# name will be adjusted so that /public/path key becomes storage_public_path
		my $name = $key;
		$name =~ s{^/+|/+$}{}g;
		$name =~ s{/+}{_}g;
		$name = "storage_$name";
		$key =~ s{/?$}{/>file};

		if ($mapping && $mapping ne '/') {
			$this_storage = Storage::Abstract->new(
				driver => 'subpath',
				source => $storage,
				subpath => $mapping,
			);
		}

		my $plack_app = Plack::App::Storage::Abstract->new(
			storage => $this_storage,
			encoding => $app->charset,
		);

		$app->add_route($key => {
			to => $plack_app->to_app,
			name => $name,
			psgi => 1,
		});
	}

	$self->register(storage => $storage);
}

1;

__END__

=head1 NAME

Kelp::Module::Storage::Abstract - Abstract file storage for Kelp

=head1 SYNOPSIS

	# in the configuration
	modules => [qw(Storage::Abstract)],
	modules_init => {
		'Storage::Abstract' => {
			driver => 'directory',
			directory => '/path/to/rootdir',
			public_routes => {
				# map URL /public to the root of the storage
				'/public' => '/',
			},
			kelp_extensions => 1,
		},
	},

=head1 DESCRIPTION

This module adds L<Storage::Abstract> instance to Kelp, along with a static
file server functionality and some file-related utility methods.

=head1 SEE ALSO

L<Kelp>

L<Storage::Abstract>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

