package SetCertHeader;

use nginx;
use URI::Encode;

my $uri = URI::Encode->new( { encode_reserved => 0 } );

sub handler {
    my $r = shift;
    my $ssl_client_cert = $r->variable('ssl_client_cert');
    
    return $uri->encode($ssl_client_cert);
}

1;
__END__