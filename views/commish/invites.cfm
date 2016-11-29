<cfoutput>

<div class="row">
	<div class="span3">
		<div class="well" style="padding: 8px 0; background-color: white;">
			<ul class="nav nav-list">
 				<li class="nav-header">Commissioner Tools</li>
				<li><a href="/commish/players/#rc.t#">Players</a></li>
				<li class="active"><a href="/commish/invites/#rc.t#">Invitations</a></li>
				<li><a href="/commish/settings/#rc.t#">Settings</a></li>
			</ul>
		</div>
	</div>
	<div class="span9">
		<h4 style="margin-top: 12px;">Send Emails</h4>
		<p>Please input an email address or a comma-separated list of addresses.<br />
		We'll send a short email with a link to join the tournament.</p>
		<div class="controls input-append" style="margin-bottom: 30px;">
			<textarea rows="3" cols="10" id="emails" style="width: 330px;"></textarea><br />
			<input type="button" class="btn" value="Send Invites" id="sendInvite">
		</div>
		
		<div id="response"></div>
		<div id="tableArea" style="margin-top: 15px;"></div>
	</div>
</div>

<script type="text/javascript">
	$('##sendInvite').on('click', function() {
		var emails = $('##emails').val();
		if (emails.length) {
			$.ajax({
				type: "post",
				url: "/services/ajax.cfc?method=sendInvite",
				data: { emailAddr: emails, t: #rc.t# }
			}).done( function(data) {
				$('##response').html(data);		
				showTable();
			});
		};
	});
	
	$(document).ready(showTable);
	
	function showTable() {
		$.ajax({
			type: "post",
			url: "/services/ajax.cfc?method=showInvites",
			data: { t: #rc.t# }
		}).done( function(data) {
			$('##tableArea').html(data);		
		});
	};
</script>

<!--- <cfdump var="#rc#"> --->

</cfoutput>