<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything" version="1.0">
  <xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
  <xsl:output encoding="UTF-8" indent="yes" method="xml"/>
  <xsl:include href="../utils.xsl"/>
  <xsl:template match="/Paytable">
    <x:stylesheet xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" version="1.0" exclude-result-prefixes="java" extension-element-prefixes="my-ext">
      <x:import href="HTML-CCFR.xsl"/>
      <x:output indent="no" method="xml" omit-xml-declaration="yes"/>
      <!--
			TEMPLATE
			Match:
			-->
      <x:template match="/">
        <x:apply-templates select="*"/>
        <x:apply-templates select="/output/root[position()=last()]" mode="last"/>
        <br/>
      </x:template>
      <lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable">
        <lxslt:script lang="javascript">
<![CDATA[
var debugFeed = [];
var debugFlag = false;
// Format instant win JSON results.
// @param jsonContext String JSON results to parse and display.
// @param translation Set of Translations for the game.
function formatJson(jsonContext, translations, prizeValues, prizeNamesDesc) {
	var scenario = getScenario(jsonContext);
	var cashSymbols = getOutcomeData(scenario, 0);
	var goldBars = getOutcomeData(scenario, 1);
	var prizeNames = (prizeNamesDesc.substring(1)).split(',');
	var convertedPrizeValues = (prizeValues.substring(1)).split('|');

	var r = [];
	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr>');
	r.push('<td class="tablehead" width="50%">');
	r.push(getTranslationByName("boardSymbols", translations));
	r.push('</td>');
	r.push('<td class="tablehead" width="50%">');
	r.push(getTranslationByName("boardValues", translations));
	r.push('</td>');
	r.push('</tr>');
	for (var idx = 0; idx < cashSymbols.length; idx++) {
		r.push('<tr>');
		r.push('<td class="tablebody" width="50%">');
		r.push(cashSymbols[idx]);
		r.push('</td>');
		r.push('<td class="tablebody" width="50%">');
		r.push(convertedPrizeValues[getPrizeNameIndex(prizeNames, cashSymbols[idx])]);
		r.push('</td>');
		r.push('</tr>');
	}
	r.push('</table>');

	// Matched symbols
	var matchedSymbols = groupSymbols(cashSymbols);
	if (matchedSymbols !== null) {
		var twoMatched = matchedSymbols.length === 2;
		r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
		r.push('<tr>');
		r.push('<td class="tablehead">');
		r.push(getTranslationByName("youMatched", translations));
		r.push('</td>');
		r.push('<td class="tablehead">');
		r.push(getTranslationByName("boardValues", translations));
		r.push('</td>');
		r.push('</tr>');
		r.push('<tr>');
		r.push('<td class="tablebody">');
		var text = matchedSymbols[0];
		if (twoMatched) {
			text += "<br>" + matchedSymbols[1];
		}
		r.push(text);
		r.push('</td>');
		r.push('<td class="tablebody">');
		text = convertedPrizeValues[getPrizeNameIndex(prizeNames, matchedSymbols[0].charAt(0))];
		if (twoMatched) {
			text += " + " + convertedPrizeValues[getPrizeNameIndex(prizeNames, matchedSymbols[1].charAt(0))];
		}
		r.push(text);
		r.push('</td>');
		r.push('</tr>');
		r.push('</table>');
	}

	// Collected gold bars
	var collectedGoldBars = collectGoldBars(goldBars);
	if (collectedGoldBars !== 0) {
		r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
		r.push('<tr>');
		r.push('<td class="tablehead">');
		r.push(getTranslationByName("goldBarCollected", translations));
		r.push('</td>');
		r.push('<td class="tablehead">');
		r.push(getTranslationByName("boardValues", translations));
		r.push('</td>');
		r.push('</tr>');
		r.push('<tr>');
		r.push('<td class="tablebody">');
		r.push(collectedGoldBars);
		r.push('</td>');
		r.push('<td class="tablebody">');
		r.push(retrieveGoldBarsValue(collectedGoldBars, convertedPrizeValues, prizeNames));
		r.push('</td>');
		r.push('</tr>');
		r.push('</table>');
	}

	// !DEBUG OUTPUT TABLE
	if (debugFlag) {
		r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
		for (var idx = 0; idx < debugFeed.length; ++idx) {
			if (debugFeed[idx] == "")
				continue;
			r.push('<tr>');
			r.push('<td class="tablebody">');
			r.push(debugFeed[idx]);
			r.push('</td>');
			r.push('</tr>');
		}
		r.push('</table>');
	}
	return r.join('');
}
function retrieveGoldBarsValue(collectedGoldBars, convertedPrizeValues, prizeNames) {
	var iw3 = convertedPrizeValues[getPrizeNameIndex(prizeNames, "I3")];
	var iw2 = convertedPrizeValues[getPrizeNameIndex(prizeNames, "I2")];
	var iw1 = convertedPrizeValues[getPrizeNameIndex(prizeNames, "I1")];
	switch (collectedGoldBars) {
		case 3:
			return iw3;
		case 4:
			return iw3 + " + " + iw2;
		case 5:
			return iw3 + " + " + iw2 + " + " + iw1;
		default:
			return "-";
	}
}
function getScenario(jsonContext) {
	var jsObj = JSON.parse(jsonContext);
	var scenario = jsObj.scenario;
	scenario = scenario.replace(/\0/g, '');
	return scenario;
}
function getOutcomeData(scenario, index) {
	var datas = scenario.split(",");
	var result = [];
	for (var idx = 0; idx < datas.length; idx++) {
		result.push(datas[idx].charAt(index));
	}
	return result;
}
function collectGoldBars(goldBars) {
	var r = 0;
	for (var idx = 0; idx < goldBars.length; idx++) {
		r += parseInt(goldBars[idx]);
	}
	return r;
}
function groupSymbols(symbols) {
	var map = {};
	for (var idx = 0; idx < symbols.length; idx++) {
		var key = symbols[idx];
		if (map[key]) {
			var count = map[key];
			count++;
			map[key] = count;
		} else {
			map[key] = 1;
		}
	}
	var result = [];
	for (var key in map) {
		if (map[key] == 3) {
			result.push(key + ", " + key + ", " + key);
		}
	}
	if (result.length > 0) {
		return result;
	}
	return null;
}
function getPrizeNameIndex(prizeNames, currPrize) {
	for (var idx = 0; idx < prizeNames.length; idx++) {
		if (prizeNames[idx] == currPrize) {
			return idx;
		}
	}
}
function getTranslationByName(keyName, translationNodeSet) {
	var index = 1;
	while (index < translationNodeSet.item(0).getChildNodes().getLength()) {
		var childNode = translationNodeSet.item(0).getChildNodes().item(index);
		if (childNode.name == "phrase" && childNode.getAttribute("key") == keyName) {
			return childNode.getAttribute("value");
		}
		index += 1;
	}
}
function registerDebugText(debugText) {
	debugFeed.push(debugText);
}
]]>
        </lxslt:script>
      </lxslt:component>
      <x:template match="root" mode="last">
        <table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
          <tr>
            <td valign="top" class="subheader">
              <x:value-of select="//translation/phrase[@key='totalWager']/@value"/>
              <x:value-of select="': '"/>
              <x:call-template name="Utils.ApplyConversionByLocale">
                <x:with-param name="multi" select="/output/denom/percredit"/>
                <x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
                <x:with-param name="code" select="/output/denom/currencycode"/>
                <x:with-param name="locale" select="//translation/@language"/>
              </x:call-template>
            </td>
          </tr>
          <tr>
            <td valign="top" class="subheader">
              <x:value-of select="//translation/phrase[@key='totalWins']/@value"/>
              <x:value-of select="': '"/>
              <x:call-template name="Utils.ApplyConversionByLocale">
                <x:with-param name="multi" select="/output/denom/percredit"/>
                <x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay"/>
                <x:with-param name="code" select="/output/denom/currencycode"/>
                <x:with-param name="locale" select="//translation/@language"/>
              </x:call-template>
            </td>
          </tr>
        </table>
      </x:template>
      <!--
			TEMPLATE
			Match:		digested/game
			-->
      <x:template match="//Outcome">
        <x:if test="OutcomeDetail/Stage = 'Scenario'">
          <x:call-template name="History.Detail"/>
        </x:if>
        <x:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
          <x:call-template name="History.Detail"/>
        </x:if>
      </x:template>
      <!--
			TEMPLATE
			Name:		Wager.Detail (base game)
			-->
      <x:template name="History.Detail">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
          <tr>
            <td class="tablebold" background="">
              <x:value-of select="//translation/phrase[@key='transactionId']/@value"/>
              <x:value-of select="': '"/>
              <x:value-of select="OutcomeDetail/RngTxnId"/>
            </td>
          </tr>
        </table>
        <x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())"/>
        <x:variable name="translations" select="lxslt:nodeset(//translation)"/>
        <x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)"/>
        <x:variable name="convertedPrizeValues">
          <x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
        </x:variable>
        <x:variable name="prizeNames">
          <x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
        </x:variable>
        <x:value-of select="my-ext:formatJson($odeResponseJson, $translations, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes"/>
      </x:template>
      <x:template match="prize" mode="PrizeValue">
        <x:text>|</x:text>
        <x:call-template name="Utils.ApplyConversionByLocale">
          <x:with-param name="multi" select="/output/denom/percredit"/>
          <x:with-param name="value" select="text()"/>
          <x:with-param name="code" select="/output/denom/currencycode"/>
          <x:with-param name="locale" select="//translation/@language"/>
        </x:call-template>
      </x:template>
      <x:template match="description" mode="PrizeDescriptions">
        <x:text>,</x:text>
        <x:value-of select="text()"/>
      </x:template>
      <x:template match="text()"/>
    </x:stylesheet>
  </xsl:template>
  <xsl:template name="TemplatesForResultXSL">
    <x:template match="@aClickCount">
      <clickcount>
        <x:value-of select="."/>
      </clickcount>
    </x:template>
    <x:template match="*|@*|text()">
      <x:apply-templates/>
    </x:template>
  </xsl:template>
</xsl:stylesheet>