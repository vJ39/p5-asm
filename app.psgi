use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;

our $VERSION = '0.11';

# put your configuration here
sub load_config {
    my $c = shift;

    my $mode = $c->mode_name || 'development';

    +{
        'DBI' => [
            'dbi:Pg:dbname=asm;host=db1',
            'asm',
            'asm',
        ],
    }
}

get '/' => sub {
    my $c = shift;
    my ($row, @select) = $c->dbh->selectrow_array('select symbolic,code from asm order by random() limit 1', {Columns => {}});
    my $st = $c->dbh->prepare('select code from asm where code <> ? order by random ()');
    $st->execute($select[0]);
    push @select, $st->fetchrow_array for(1..2);
    $st->finish;
    return $c->render('index.tt', {symbolic => uc($row), select => [sort{$a cmp $b} @select]});
};
get '/a' => sub {
    my $c = shift;
    my $row = $c->dbh->selectrow_array('select * from asm where symbolic = ? and code = ?', {Columns => {}}, uc($c->req->param('symbolic')), uc($c->req->param('code')));
    my ($symbolic, $code) = $c->dbh->selectrow_array('select symbolic, code from asm where symbolic = ?', {Columns => {}}, uc($c->req->param('symbolic')));
    my $incorrect = 0;
    if(!$row){$incorrect = 1}
    return $c->render('ans.tt', {incorrect => $incorrect, symbolic => uc($symbolic), code => uc($code), answer => uc($c->req->param('code')) });
};
get '/l' => sub {
    my $c = shift;
    my $data = $c->dbh->selectall_arrayref('select symbolic, code from asm where code between ? and ? and length(code) = 2 order by code', undef , '00', 'FF');
    return $c->render('list.tt', {data => $data});
};

# load plugins
__PACKAGE__->load_plugin('Web::CSRFDefender' => {
    post_only => 1,
});
__PACKAGE__->load_plugin('DBI');
__PACKAGE__->load_plugin('Web::FillInFormLite');
# __PACKAGE__->load_plugin('Web::JSON');

#__PACKAGE__->enable_session();

__PACKAGE__->to_app(handle_static => 1);

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>assembler karuta training</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/main.js') %]"></script>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="[% uri_for('/static/css/main.css') %]">
</head>
<body>
    <div class="container">
        <header><h3>assembler karuta training</h3></header>
        <section class="row">
            <form action="/a" method="get">
            [% IF incorrect %]<span style="color:red;font-weight:bolder;">X</span>[% END %]
            <input type="hidden" name="symbolic" value="[% symbolic %]" />
            <input type="hidden" name="code" />
            <h1>[% symbolic %]</h1>
            <div class="form-actions">
            <p>
            [% FOR i IN [0..2] -%]
            <a class="btn btn-large btn-primary" href="#" onclick="d=document.forms[0];d.code.value='[% select.${i} %]';d.submit();return false">[% select.${i} %]</a>
            [% END -%]
            </p>
            </div>
            </form>
        </section>
        <section>
        <div><i class="icon-question-sign"></i><a href="/l" target="_hint">hint</a></div>
        </section>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
</body>
</html>

@@ list.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>assembler karuta training</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/main.js') %]"></script>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="[% uri_for('/static/css/main.css') %]">
</head>
<body>
    <div class="container">
        <header><h3>assembler karuta training</h3></header>
        <section class="row">
            <table class="table table-striped table-bordered">
            <thead>
            <th>&nbsp;</th>
            [% FOR i IN [0..9,'A'..'F'] -%]
            <th>[% i %]</th>
            [% END -%]
            </thread>
            <tbody>
            [% v = data.shift() -%]
            [% FOR h IN [0..9,'A'..'F'] -%]
            <tr>
                <th>[% h %]</th>
                [% FOR w IN [0..9,'A'..'F'] -%]
                <td><small>[% IF v[1] == (h _ w) %][% v[0]; v = data.shift()%]
                [% ELSE -%]-[% END %]</small></td>
                [% END -%]
            </tr>
            [% END -%]
            </tbody>
            </table>
        </section>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
</body>
</html>

@@ ans.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>assembler karuta training</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
    <script type="text/javascript" src="[% uri_for('/static/js/main.js') %]"></script>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="[% uri_for('/static/css/main.css') %]">
</head>
<body>
    <div class="container">
        <header><h3>assembler karuta training</h3></header>
        <section class="row">
            <h1>[% symbolic %]</h1>
            [% IF incorrect %]<p style="color:red;font-weight:bolder;font-size:500%">X</p>
            <p>YOUR ANSWER:<br />
            [% answer %]</p>
            [% ELSE %]
            <p style="color:green;font-weight:bolder;font-size:500%">O</p>[% END %]
            <p>CORRECT ANSWER:<br />
            <span style="font-size:200%">[% code %]</span></p>
            <a href="/" class="btn">Next</a>
        </section>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
</body>
</html>

@@ /static/js/main.js
true;

@@ /static/css/main.css
footer {
    text-align: right;
}
