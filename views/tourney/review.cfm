<cfset rc.pageTitle = "#rc.tourneyBasics.name#: Review Bet">
<cfoutput>

<br />
<h3>Review Bet</h3>

<div class="row">
	<div class="span6">
		<div class="alert alert-info">
			<ul style="margin-bottom: 0;">
			<cfloop array="#rc.betArray#" index="itm">
				<li id="#itm.segmentID#" multiplier="#itm.multiplier#">#itm.displayText#</li>
			</cfloop>
			</ul>
		</div>
	
 		<p>$100 wagered wins #dollarFormat( 100 * val( rc.multiplier ) )#</p>
		<p>Available to bet: #dollarFormat( val( rc.totals.bankroll ) - val( rc.totals.atRisk ) )#</p> 
		<br />
		<cfif structKeyExists( rc, "returnMsg" )>
			<p><i class="icon-hand-right"></i> <strong>#rc.returnMsg#</strong></p>
		</cfif>
		
		<p>Amount to Wager?</p>
		<cfform action="/tourney/confirm_form/#rc.t#" method="post" class="form-inline">
			<div class="input-prepend">
				<span class="add-on">$</span><input type="text" class="span2" name="amount" />
			</div>
			<cfif structKeyExists( rc, "betString" )>
				<input type="hidden" name="betString" value="#rc.betString#" />
				<input type="hidden" name="betType" value="game">
			<cfelse>
				<input type="hidden" name="propString" value="#rc.propString#" />
				<input type="hidden" name="betType" value="prop">
			</cfif>			
			<input type="submit" value="review" name="submit" class="btn" />
		</cfform>
		
		<p><small>*You will have a chance to confirm this bet on the following page.</small></p>
	</div>
</div>

</cfoutput>
<!--- 
<cfdump var="#rc#">
 --->
