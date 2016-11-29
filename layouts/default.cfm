<!---This is the site wide layout--->
<cfoutput>

<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<title>Sharp League <cfif structKeyExists( rc, "pageTitle" )> | #rc.pageTitle#</cfif></title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<cfif structKeyExists( rc, "pageDesc" )>
			<meta name="description" content="#rc.pageDesc#">
		</cfif>
		<link href="/css/bootstrap.css" rel="stylesheet">
		<link href="/css/bootstrap-responsive.css" rel="stylesheet">
		<link href="/css/adds.css" rel="stylesheet">
		
		<!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
		<!--[if lt IE 9]>
		  <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
		<![endif]-->
		<link rel="shortcut icon" href="/images/ico/favicon.ico">
<!--- 		<link rel="apple-touch-icon-precomposed" sizes="144x144" href="/images/ico/apple-touch-icon-144-precomposed.png">
		<link rel="apple-touch-icon-precomposed" sizes="114x114" href="/images/ico/apple-touch-icon-114-precomposed.png">
		<link rel="apple-touch-icon-precomposed" sizes="72x72" href="/images/ico/apple-touch-icon-72-precomposed.png">
		<link rel="apple-touch-icon-precomposed" href="/images/ico/apple-touch-icon-57-precomposed.png"> --->

	<cfif cgi.http_host NEQ "localsharp2">		
		<script type="text/javascript">
			var _gaq = _gaq || [];
			_gaq.push(['_setAccount', 'UA-18567368-1']);
			_gaq.push(['_trackPageview']);
			(function() {
			  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
			  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
			  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
			})();
		</script>
	</cfif>
		<script src="/scripts/jquery-1.8.0.js"></script>
		<script src="/scripts/bootstrap.js"></script>
	</head>

	<body>
		<div class="container">
			#body#
			<hr>
			<div class="center">
				<p><small>&copy;#year( now() )# Sharp League, LLC 
					| <a href="/front/privacy">Privacy</a>
					| <a href="/front/terms">Terms</a>
					| <a href="/front/faq">FAQ / Contact</a></small></p>
			</div>
		</div>
	</body>
</html>

</cfoutput>