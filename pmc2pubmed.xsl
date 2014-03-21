<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:redirect="http://www.pubmedcentral.gov/redirect" 
	xmlns:xalan="http://xml.apache.org/xalan" extension-element-prefixes="xalan" 
	exclude-result-prefixes="xlink redirect">

	<!-- 
		pmc2pubmed.xsl
		=============================================================
		This stylesheet transforms instances of PMC Style-compliant 
		JATS XML to pubmed records. It has been altered from the PMC
		post-processing stylesheet for more general use.
		=============================================================
		2014/03/20
	-->

	<xsl:output method="xml" omit-xml-declaration="yes" indent="yes" 
		doctype-public="-//NLM//DTD PubMed//EN" doctype-system="http://www.ncbi.nlm.nih.gov/corehtml/query/static/PubMed.dtd"/>

	<xsl:strip-space elements="*"/>
	<xsl:preserve-space elements="p"/>

	<xsl:variable name="issn" select="article/front/journal-meta/issn"/>

	<xsl:variable name="doi-info"/>

	<xsl:template match="/">
		<ArticleSet>
			<Article>
				<xsl:apply-templates/>
			</Article>
		</ArticleSet>
	</xsl:template>
	
	<xsl:template match="article">
		<xsl:variable name="ppub" select="front/article-meta/pub-date[@pub-type='ppub'] | front/article-meta/pub-date[@pub-type='collection']"/>
		<xsl:variable name="epub" select="front/article-meta/pub-date[@pub-type='epub']"/>
	    <xsl:variable name="article-lang">
	        <xsl:call-template name="capitalize">
	            <xsl:with-param name="str" select="@xml:lang"/>
	        </xsl:call-template>
	    </xsl:variable>
	    <xsl:variable name="article-title-lang">
	        <xsl:call-template name="capitalize">
	            <xsl:with-param name="str" select="descendant::article-title/@xml:lang"/>
	        </xsl:call-template>
	    </xsl:variable>
	    <xsl:variable name="trans-title-lang">
	        <xsl:call-template name="capitalize">
	            <xsl:with-param name="str" select="descendant::trans-title/@xml:lang"/>
	        </xsl:call-template>
	    </xsl:variable>
	    <xsl:variable name="alt-title-lang">
	        <xsl:call-template name="capitalize">
	            <xsl:with-param name="str" select="descendant::alt-title/@xml:lang"/>
	        </xsl:call-template>
	    </xsl:variable>
		<Journal>
			<xsl:choose>
				<xsl:when test="front/journal-meta/publisher/publisher-name/text()">
					<xsl:apply-templates select="front/journal-meta/publisher/publisher-name"/>
				</xsl:when>
				<xsl:otherwise>
					<PublisherName>PMC</PublisherName>
				</xsl:otherwise>
			</xsl:choose>
			<JournalTitle>
				<xsl:choose>
					<xsl:when test="descendant::journal-id[@journal-id-type='nlm-ta']">
						<xsl:value-of select="descendant::journal-id[@journal-id-type='nlm-ta']"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="descendant::journal-id[@journal-id-type='iso-abbrev']"/>
					</xsl:otherwise>
				</xsl:choose>
			</JournalTitle>
			<Issn>
				<xsl:choose>
					<xsl:when test="descendant::article-meta/pub-date[@pub-type='collection']">
						<xsl:value-of select="descendant::issn[@pub-type='epub']"/>
					</xsl:when>
				    <xsl:when test="contains(descendant::issn[@pub-type='ppub'],'-')">
				        <xsl:value-of select="descendant::issn[@pub-type='ppub']"/>
					</xsl:when>
					<xsl:otherwise>
					    <xsl:value-of select="descendant::issn[@pub-type='epub']"/>
					</xsl:otherwise>
				</xsl:choose>
			</Issn>
			<xsl:apply-templates select="front/article-meta/volume"/>
			<xsl:apply-templates select="front/article-meta/issue"/>
			<xsl:call-template name="PubDate"/>
		</Journal>

		<xsl:apply-templates select="front/article-meta/title-group"/>

		<xsl:choose>
			<xsl:when test="front/article-meta/elocation-id">
				<xsl:choose>
					<xsl:when test="starts-with(front/article-meta/elocation-id,'10.')">
						<ELocationID EIdType="doi">
							<xsl:value-of select="front/article-meta/elocation-id"/>
						</ELocationID>
					</xsl:when>
					<xsl:when test="translate(front/article-meta/elocation-id,'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789','')!=''">
						<ELocationID EIdType="pii">
							<xsl:value-of select="front/article-meta/elocation-id"/>
						</ELocationID>
					</xsl:when>
					<xsl:otherwise>
					    <FirstPage LZero="save">
							<xsl:value-of select="front/article-meta/elocation-id"/>
						</FirstPage>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
			    <FirstPage LZero="save">
					<xsl:call-template name="stripdash">
						<xsl:with-param name="str" select="front/article-meta/fpage"/>
					</xsl:call-template>
				</FirstPage>
				<xsl:if test="front/article-meta/lpage">
					<LastPage>
						<xsl:call-template name="stripdash">
							<xsl:with-param name="str" select="front/article-meta/lpage"/>
						</xsl:call-template>
					</LastPage>
				</xsl:if>				
			</xsl:otherwise>
		</xsl:choose>

	    <xsl:choose>
	        <xsl:when test="($article-lang or $article-title-lang) != ($trans-title-lang or $alt-title-lang)">			
	            <xsl:for-each select="descendant-or-self::node()[self::article or self::article-title or self::trans-title or self::alt-title]
     			    [@xml:lang and @xml:lang!='en' and @xml:lang!='EN' and @xml:lang!='en-us' and @xml:lang!='EN-US']">
     				<Language>
     					<xsl:call-template name="capitalize">
     						<xsl:with-param name="str" select="@xml:lang"/>
     					</xsl:call-template>
     				</Language>
     			</xsl:for-each>
	            <xsl:if test="descendant-or-self::node()[self::article or self::article-title or self::trans-title or self::alt-title]
     	            [@xml:lang='en' or @xml:lang='EN' or @xml:lang='en-us' or @xml:lang='EN-US']">
     	           <Language>EN</Language>
     	        </xsl:if>
	        </xsl:when>
	        <xsl:when test="@xml:lang!='EN' and @xml:lang!='EN-US'">
	            <Language>
	                <xsl:call-template name="capitalize">
	                    <xsl:with-param name="str" select="@xml:lang"/>
	                </xsl:call-template>
	            </Language>
	        </xsl:when>
		</xsl:choose>

		<xsl:apply-templates select="front/article-meta/contrib-group"/>

		<!-- publicationtype -->
		<xsl:if test="@article-type='correction'">
			<PublicationType>Published Erratum</PublicationType>
		</xsl:if>
		<xsl:if test="@article-type='retraction'">
			<PublicationType>Retraction of Publication</PublicationType>
		</xsl:if>
	    <xsl:if test="@article-type='review-article'">
	        <PublicationType>Review</PublicationType>
	    </xsl:if>

		<!-- pubidlist -->
		<xsl:if test="front/article-meta/article-id[@pub-id-type='doi'] or
			front/article-meta/article-id[@pub-id-type='knolid']">
			<ArticleIdList>
				<xsl:apply-templates select="front/article-meta/article-id[@pub-id-type='doi']"/>
				<xsl:apply-templates select="front/article-meta/article-id[@pub-id-type='knolid']"/>
				<xsl:apply-templates select="front/article-meta/article-id[@pub-id-type='publisher-id']"/>
			</ArticleIdList>
		</xsl:if>

		<xsl:if test="front/article-meta/history/date[@date-type='received'] | 
			front/article-meta/history/date[@date-type='rev-recd'] | 
			front/article-meta/history/date[@date-type='accepted'] | 
			front/article-meta/pub-date[@pub-type='epub'][day]">
			<History>
				<xsl:apply-templates select="front/article-meta/history/date[@date-type='received']"/>
				<xsl:apply-templates select="front/article-meta/history/date[@date-type='rev-recd']"/>
				<xsl:apply-templates select="front/article-meta/history/date[@date-type='accepted']"/>

				<xsl:if test="$ppub!=$epub">
					<xsl:if test="front/article-meta/pub-date[@pub-type='epub']/day">
						<!-- Do not process if there is no epub day -->
						<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']"/>
					</xsl:if>
				</xsl:if>
			</History>
		</xsl:if>

		<xsl:choose>
			<xsl:when test="front/article-meta/abstract[@xml:lang='en'] or front/article-meta/abstract[@xml:lang='EN']">
				<xsl:apply-templates select="front/article-meta/abstract[@xml:lang='en'] | front/article-meta/abstract[@xml:lang='EN']"/>
			</xsl:when>
			<xsl:when test="front/article-meta/trans-abstract[@xml:lang='en'] or front/article-meta/trans-abstract[@xml:lang='EN']">
				<xsl:apply-templates select="front/article-meta/trans-abstract[@xml:lang='en'] | front/article-meta/trans-abstract[@xml:lang='EN']"/>
			</xsl:when>
			<xsl:when test="front/article-meta/abstract[not(attribute::abstract-type)]">
				<xsl:apply-templates select="front/article-meta/abstract[not(@abstract-type) and not(@xml:lang)]"/>
			</xsl:when>
			<xsl:when test="front/article-meta/abstract[@abstract-type='short']">
				<xsl:apply-templates select="front/article-meta/abstract[@abstract-type='short']"/>
			</xsl:when>
			<xsl:when test="front/article-meta/abstract">
				<xsl:apply-templates select="front/article-meta/abstract[not(@xml:lang)][1]"/>
			</xsl:when>
			<xsl:otherwise>
			    <xsl:if test="descendant::related-article[@related-article-type='corrected-article']">
					<Abstract>
					    <xsl:for-each select="descendant::related-article[@related-article-type='corrected-article']">
							<xsl:call-template name="build-cx-relart"/>
						</xsl:for-each>
					</Abstract>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

	    <xsl:if test="descendant::contract-num | descendant::grant-num">
			<ObjectList>
				<xsl:call-template name="build-grants">
				    <xsl:with-param name="nodes" select="descendant::contract-num | descendant::grant-num"/>
				</xsl:call-template>
			</ObjectList>
		</xsl:if>

	</xsl:template>
	
	<!-- ==== Grant Templates ==== -->

	<xsl:template name="build-grants">
		<xsl:param name="nodes"/>
		<xsl:for-each select="$nodes">
			<xsl:variable name="rid" select="@rid"/>
			<Object Type="grant">
				<Param Name="id">
					<xsl:value-of select="."/>
				</Param>
				<Param Name="grantor">
					<xsl:call-template name="clean-grantor">
					    <xsl:with-param name="str" select="descendant::contract-sponsor[@id=$rid][1]/text()|
					        descendant::grant-sponsor[@id=$rid][1]/text()"/>
					</xsl:call-template>
				</Param>
			</Object>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="clean-grantor">
		<xsl:param name="str"/>
		<xsl:choose>
			<xsl:when test="contains($str,' : ')">
				<xsl:value-of select="concat('United States ',substring-after($str,' : '))"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- If no : to delineate column, assume it's UK -->
				<xsl:value-of select="concat('United Kingdom ',$str)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="build-grants-from-pi">
		<xsl:param name="str"/>
		<xsl:variable name="country" select="substring-after(substring-after(substring-after(substring-after(substring-after($str,'|'),'|'),'|'),'|'),'|')"/>
		<xsl:variable name="grantno" select="substring-before(substring-after($str,'|'),'|')"/>
		<xsl:variable name="agency">
			<xsl:choose>
				<xsl:when test="contains(substring-before($str,'|'),'Howard Hughes')">
					<xsl:value-of select="substring-before($str, '|')"/>
				</xsl:when>
				<xsl:when test="$country='United States'">
					<xsl:value-of select="substring-before(substring-after(substring-after(substring-after($str,'|'),'|'),'|'),'|')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-before($str,'|')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<Object Type="grant">
			<xsl:if test="$agency != 'Howard Hughes Medical Institute'">
				<Param Name="id">
					<xsl:value-of select="$grantno"/>
				</Param>
			</xsl:if>
			<Param Name="grantor">
				<xsl:value-of select="concat($country,' ',$agency)"/>
			</Param>
		</Object>
	</xsl:template>
	
	<!-- ==== Correction link ==== -->

	<xsl:template name="build-cx-relart">
		<xsl:text>[This corrects the article </xsl:text>
		<xsl:choose>
			<xsl:when test="@page">
				<xsl:text>on p. </xsl:text>
				<xsl:value-of select="@page"/>
				<xsl:text> in vol. </xsl:text>
				<xsl:value-of select="@vol"/>
			</xsl:when>
			<xsl:when test="@ext-link-type='doi'">
				<xsl:text>DOI: </xsl:text>
				<xsl:value-of select="@xlink:href"/>
			</xsl:when>
		</xsl:choose>
		<xsl:if test="@xlink:href and @ext-link-type='pubmed'">
			<xsl:text>, PMID: </xsl:text>
			<xsl:value-of select="@xlink:href"/>
		</xsl:if>
		<xsl:text>.]</xsl:text>
	</xsl:template>
	
	<!-- ==== Citation information ==== -->

	<xsl:template match="publisher-name">
		<PublisherName>
			<xsl:value-of select="."/>
		</PublisherName>
	</xsl:template>

	<xsl:template match="volume[not(ancestor::abstract)]">
		<Volume>
			<xsl:apply-templates/>
		</Volume>
	</xsl:template>

	<xsl:template match="issue[not(ancestor::abstract)]">
		<Issue>
			<xsl:apply-templates/>
			<xsl:if test="following-sibling::supplement">
				<xsl:choose>
					<xsl:when test="contains(.,'Sup') or contains(.,'sup') or contains(following-sibling::supplement,'Sup') or contains(following-sibling::supplement,'sup')">
						<xsl:text> </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> Suppl </xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="following-sibling::supplement"/>
			</xsl:if>
		</Issue>
	</xsl:template>

	<xsl:template name="PubDate">
		<xsl:choose>
			<xsl:when test="front/article-meta/pub-date/@pub-type='ppub' and front/article-meta/pub-date/@pub-type='epub'">
				<!-- When ppub and epub both exist, write ppub as PubDate and epub in History.
					 PubMed loader picks up epub date from history and converts it to PubDate PubStatus="epub" -->
				<PubDate PubStatus="ppublish">
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/year"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/month"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/day"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/season"/>
				</PubDate>
			</xsl:when>
			<xsl:when test="(count(front/article-meta/pub-date[@pub-type!='pmc-release'])>1 and 
				front/article-meta/pub-date[@pub-type='epub'] and front/article-meta/pub-date[@pub-type='collection'] and 
				not(front/article-meta/pub-date[@pub-type='epub']/day)) or (count(front/article-meta/pub-date[@pub-type!='pmc-release'])=1 and
				front/article-meta/pub-date[@pub-type='epub'] and not(front/article-meta/pub-date/day))">
				<!-- When only pub-date is epub and there is no day, do not write @PubStatus. 
					 PubStatus="epublish" requires Day element which we don't have. -->
				<PubDate>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/year"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/month"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/season"/>
				</PubDate>
			</xsl:when>
			<xsl:when test="count(front/article-meta/pub-date[@pub-type!='pmc-release'][@pub-type!='epreprint'])=1 and
				front/article-meta/pub-date[@pub-type='epub']">
				<!-- When there's only 1 pub-date and it's an epub date, send as epublilsh and do
					not send ppublish value -->
				<PubDate PubStatus="epublish">
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/year"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/month"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/day"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/season"/>
				</PubDate>
			</xsl:when>
			<xsl:when test="count(front/article-meta/pub-date[@pub-type!='pmc-release'])>1 and front/article-meta/pub-date[@pub-type='epub'] and
				front/article-meta/pub-date[@pub-type='collection']">
				<!-- If we have epub and collection, send collection as PubDate, epub in History -->
				<PubDate>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='collection']/year"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='collection']/month"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='collection']/day"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='collection']/season"/>
				</PubDate>
			</xsl:when>
			<xsl:when test="front/article-meta/pub-date[@pub-type='nihms-submitted'] and not(front/article-meta-pub-date[@pub-type='ppub']) 
				and front/article-meta/pub-date[@pub-type='epub']">
				<!-- When there's an nihms-submitted date, no ppub date, but an epub date, send that without PubStatus -->
				<PubDate>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/year"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/month"/>
					<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']/day"/>
				</PubDate>
			</xsl:when>
			<xsl:otherwise>
				<PubDate PubStatus="ppublish">
					<xsl:choose>
						<xsl:when test="front/article-meta/pub-date[@pub-type='ppub']">
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/year"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/month"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/day"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/season"/>
						</xsl:when>
						<xsl:when test="front/article-meta/pub-date[@pub-type='collection']">
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='collection']/year"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='collection']/month"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='collection']/day"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']/season"/>
						</xsl:when>
						<xsl:when test="front/article-meta/pub-date[@pub-type='epub-ppub']">
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub-ppub']/year"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub-ppub']/month"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub-ppub']/day"/>
							<xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub-ppub']/season"/>
						</xsl:when>
					</xsl:choose>
				</PubDate>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="title-group">
		<xsl:choose>
			<xsl:when test="ancestor::article/@xml:lang='EN' or ancestor::article/@xml:lang='en'">
				<ArticleTitle>
					<xsl:choose>
						<xsl:when test="ancestor::article/@article-type='correction'">
							<xsl:choose>
								<xsl:when test="starts-with(article-title,'Correction') or starts-with(article-title, 'Erratum')
									or starts-with(article-title, 'Errata')"/>
								<xsl:otherwise>
									<xsl:text>Erratum: </xsl:text>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:apply-templates select="article-title"/>
							<xsl:if test="subtitle">
								<xsl:text>: </xsl:text>
								<xsl:apply-templates select="subtitle"/>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="article-title"/>
							<xsl:if test="subtitle">
								<xsl:text>: </xsl:text>
								<xsl:apply-templates select="subtitle"/>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</ArticleTitle>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="trans-title[@xml:lang='en' or @xml:lang='EN']">
					<ArticleTitle>
						<xsl:apply-templates select="trans-title"/>
					</ArticleTitle>
				</xsl:if>
				<xsl:if test="trans-title-group[@xml:lang='en' or @xml:lang='EN'] or trans-title-group/trans-title[@xml:lang='en' or @xml:lang='EN'] ">
					<ArticleTitle>
						<xsl:apply-templates select="trans-title-group/trans-title"/>
					</ArticleTitle>
				</xsl:if>
				<VernacularTitle>
					<xsl:apply-templates select="article-title"/>
					<xsl:if test="subtitle">
						<xsl:text>: </xsl:text>
						<xsl:apply-templates select="subtitle"/>
					</xsl:if>
				</VernacularTitle>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="article-title | subtitle | trans-title">
		<xsl:apply-templates select="*[not(self::fnr) and not(self::xref)]|text()"/>
	</xsl:template>

	<!-- ==== Date Templates ==== -->

	<xsl:template name="get_pubmonth">
		<xsl:param name="month"/>
		<Month>
			<xsl:choose>
				<xsl:when test="$month='1' or $month='01'">Jan</xsl:when>
				<xsl:when test="$month='2' or $month='02'">Feb</xsl:when>
				<xsl:when test="$month='3' or $month='03'">Mar</xsl:when>
				<xsl:when test="$month='4' or $month='04'">Apr</xsl:when>
				<xsl:when test="$month='5' or $month='05'">May</xsl:when>
				<xsl:when test="$month='6' or $month='06'">Jun</xsl:when>
				<xsl:when test="$month='7' or $month='07'">Jul</xsl:when>
				<xsl:when test="$month='8' or $month='08'">Aug</xsl:when>
				<xsl:when test="$month='9' or $month='09'">Sept</xsl:when>
				<xsl:when test="$month='10'">Oct</xsl:when>
				<xsl:when test="$month='11'">Nov</xsl:when>
				<xsl:when test="$month='12'">Dec</xsl:when>
			</xsl:choose>
		</Month>
	</xsl:template>

	<xsl:template match="date[@date-type='received']">
		<xsl:if test="day">
			<PubDate PubStatus="received">
				<xsl:apply-templates select="year"/>
				<xsl:apply-templates select="month"/>
				<xsl:apply-templates select="day"/>
			</PubDate>
		</xsl:if>
	</xsl:template>

	<xsl:template match="date[@date-type='rev-recd']">
		<xsl:if test="day">
			<PubDate PubStatus="revised">
				<xsl:apply-templates select="year"/>
				<xsl:apply-templates select="month"/>
				<xsl:apply-templates select="day"/>
			</PubDate>
		</xsl:if>
	</xsl:template>

	<xsl:template match="date[@date-type='accepted']">
		<xsl:if test="day">
			<PubDate PubStatus="accepted">
				<xsl:apply-templates select="year"/>
				<xsl:apply-templates select="month"/>
				<xsl:apply-templates select="day"/>
			</PubDate>
		</xsl:if>
	</xsl:template>

	<xsl:template match="pub-date[@pub-type='epub']">
		<PubDate PubStatus="epublish">
			<xsl:apply-templates select="year"/>
			<xsl:apply-templates select="month"/>
			<xsl:apply-templates select="day"/>
		</PubDate>
	</xsl:template>

	<xsl:template match="year">
		<Year>
			<xsl:apply-templates/>
		</Year>
	</xsl:template>

	<xsl:template match="day">
		<Day>
			<xsl:apply-templates/>
		</Day>
	</xsl:template>

	<xsl:template match="month">
		<Month>
			<xsl:apply-templates/>
		</Month>
	</xsl:template>

	<xsl:template match="season">
		<Season>
			<xsl:apply-templates/>
		</Season>
	</xsl:template>
	
	<!-- ==== Contrib templates ==== -->
	
	<xsl:template match="contrib-group[1]">
		<AuthorList>
			<xsl:for-each select="contrib[not(attribute::contrib-type='editor')]">
				<xsl:apply-templates select=".">
					<xsl:with-param name="position" select="position()"/>
				</xsl:apply-templates>
			</xsl:for-each>
			<!-- grab autors from other contrib groups in article-meta -->
			<xsl:for-each select="following-sibling::contrib-group/contrib[not(attribute::contrib-type='editor')]">
				<xsl:apply-templates select=".">
					<xsl:with-param name="position" select="position()"/>
				</xsl:apply-templates>
			</xsl:for-each>
		</AuthorList>
		<xsl:if test="contrib/collab/contrib-group">
			<GroupList>
				<xsl:for-each select="contrib/collab[contrib-group]">
					<Group>
						<GroupName>
							<xsl:apply-templates select="text()"/>
						</GroupName>
						<xsl:for-each select="contrib-group/contrib">
							<IndividualName>
								<xsl:apply-templates select="name/given-names"/>
								<xsl:apply-templates select="name/surname"/>
								<xsl:apply-templates select="name/suffix"/>
								<xsl:apply-templates select="aff[1]" mode="group-list"/>
							</IndividualName>
						</xsl:for-each>
					</Group>
				</xsl:for-each>
			</GroupList>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="contrib-group[position()!=1]"/>

	<xsl:template match="contrib[not(attribute::contrib-type='editor')]">
		<xsl:param name="position"/>
		<xsl:variable name="clean-fname" select="normalize-space(name/given-names)"/>

		<xsl:variable name="fname" select="substring($clean-fname,2,1)"/>
		<xsl:variable name="ftest">
			<xsl:call-template name="capitalize">
				<xsl:with-param name="str" select="substring($clean-fname,2,1)"/>
			</xsl:call-template>
		</xsl:variable>
		<!--	called by for-each so position will always be 1
			xsl:variable name="auno" select="position()"/ -->
		<xsl:variable name="firstau">
			<xsl:choose>
				<xsl:when test="preceding-sibling::contrib[not(attribute::contrib-type='editor')]">
					<xsl:text>no</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>yes</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="refid" select="xref[@ref-type='aff'][1]/@rid"/>
		<Author>
			<xsl:choose>
				<xsl:when test="collab">
					<CollectiveName>
						<xsl:apply-templates select="collab/*[not(self::contrib-group)] | collab/text()"/>
					</CollectiveName>
				</xsl:when>
				<xsl:otherwise>
					<FirstName>
						<xsl:choose>
							<xsl:when test="name[@content-type='index']/given-names/node()">
								<xsl:choose>
									<xsl:when test="name[@content-type='index']/given-names/@initials">
										<xsl:choose>
											<xsl:when test="string-length(name[@content-type='index']/given-names) > string-length(name[@content-type='index']/given-names/@initials)">
												<xsl:value-of select="normalize-space(name[@content-type='index']/given-names)"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:call-template name="process-initials">
													<xsl:with-param name="str" select="name[@content-type='index']/given-names/@initials"/>
												</xsl:call-template>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="normalize-space(name[@content-type='index']/given-names)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test="name/given-names/node()">
								<xsl:choose>
									<xsl:when test="name/given-names/@initials">
										<xsl:choose>
											<xsl:when test="string-length(name/given-names) > string-length(name/given-names/@initials)">
												<xsl:value-of select="normalize-space(name/given-names)"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:call-template name="process-initials">
													<xsl:with-param name="str" select="name/given-names/@initials"/>
												</xsl:call-template>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="normalize-space(name/given-names)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>
								<xsl:attribute name="EmptyYN">
									<xsl:value-of select="'Y'"/>
								</xsl:attribute>
							</xsl:otherwise>
						</xsl:choose>
					</FirstName>
					<LastName>
						<xsl:choose>
							<xsl:when test="name[@content-type='index']">
								<xsl:value-of select="normalize-space(name[@content-type='index']/surname)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="normalize-space(name/surname)"/>
							</xsl:otherwise>
						</xsl:choose>
					</LastName>
					<xsl:apply-templates select="name/suffix"/>
					<xsl:if test="$firstau='yes'">
						<xsl:choose>
							<xsl:when test="aff">
								<xsl:choose>
									<xsl:when test="count(ancestor::article//article-meta//aff[@id]) > 1 and xref[@ref-type='aff']">
										<xsl:apply-templates select="aff[@id=$refid]"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:apply-templates select="aff[1]"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="count(ancestor::article//article-meta//aff) > 1 and xref[@ref-type='aff']">
										<xsl:choose>
											<xsl:when test="count(xref[@ref-type='aff']) > 1">
												<xsl:choose>
													<xsl:when test="ancestor::contrib-group/aff">
														<Affiliation>
															<xsl:for-each select="xref[@ref-type='aff']">
																<xsl:variable name="my-rid" select="@rid"/>
																<xsl:apply-templates select="ancestor::contrib-group/aff[@id=$my-rid]">
																	<xsl:with-param name="in-aff" select="'yes'"/>
																</xsl:apply-templates>
																<xsl:if test="following-sibling::xref[@ref-type='aff']">
																	<xsl:text>; </xsl:text>
																</xsl:if>
															</xsl:for-each>
														</Affiliation>
													</xsl:when>
													<xsl:otherwise>
														<Affiliation>
															<xsl:for-each select="xref[@ref-type='aff']">
																<xsl:variable name="my-rid" select="@rid"/>
																<xsl:apply-templates select="ancestor::contrib-group/following-sibling::aff[@id=$my-rid]">
																	<xsl:with-param name="in-aff" select="'yes'"/>
																</xsl:apply-templates>
																<xsl:if test="following-sibling::xref[@ref-type='aff']">
																	<xsl:text>; </xsl:text>
																</xsl:if>
															</xsl:for-each>
														</Affiliation>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:when>
											<xsl:otherwise>
												<xsl:choose>
													<xsl:when test="ancestor::contrib-group/aff">
														<xsl:apply-templates select="ancestor::contrib-group/aff[@id=$refid]"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:apply-templates select="ancestor::contrib-group/following-sibling::aff[@id=$refid]"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test="following-sibling::aff">
										<xsl:apply-templates select="following-sibling::aff[1]"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:apply-templates select="ancestor::contrib-group/following-sibling::aff[1]"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</Author>
	</xsl:template>

	<xsl:template name="process-initials">
		<xsl:param name="str"/>
		<xsl:if test="$str">
			<xsl:choose>
				<xsl:when test="string-length($str) > 1">
					<xsl:value-of select="substring($str,1,1)"/>
					<xsl:text> </xsl:text>
					<xsl:call-template name="process-initials">
						<xsl:with-param name="str" select="substring($str,2)"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$str"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template match="given-names">
		<xsl:choose>
			<xsl:when test="contains(normalize-space(.),' ')">
				<FirstName>
					<xsl:value-of select="substring-before(normalize-space(.),' ')"/>
				</FirstName>
				<MiddleName>
					<xsl:call-template name="nodot">
						<xsl:with-param name="str" select="substring-after(normalize-space(.),' ')"/>
					</xsl:call-template>
				</MiddleName>
			</xsl:when>
			<xsl:otherwise>
				<FirstName>
					<xsl:value-of select="normalize-space(.)"/>
				</FirstName>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="surname[not(ancestor::abstract)]">
		<LastName>
			<xsl:value-of select="normalize-space(.)"/>
		</LastName>
	</xsl:template>

	<xsl:template match="suffix">
		<Suffix>
			<xsl:apply-templates/>
		</Suffix>
	</xsl:template>

	<xsl:template match="aff">
		<xsl:param name="insr"/>
		<xsl:param name="in-aff"/>
		<xsl:choose>
			<!-- Affiliation element already written in contrib match -->
			<xsl:when test="$in-aff='yes'">
				<xsl:choose>
					<xsl:when test="count(label) > 1 and label[1]=$insr">
						<xsl:call-template name="fix-aff-punct">
							<xsl:with-param name="str" select="normalize-space(text()[1])"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="count(sup) > 1 and sup[1]=$insr">
						<xsl:call-template name="fix-aff-punct">
							<xsl:with-param name="str" select="normalize-space(text()[1])"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="*[not(self::label) and not(self::sup) and not(self::bold)]|text()">
							<xsl:apply-templates select="self::node()"/>
							<xsl:text> </xsl:text>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<Affiliation>
					<xsl:choose>
						<xsl:when test="count(label) > 1 and label[1]=$insr">
							<xsl:call-template name="fix-aff-punct">
								<xsl:with-param name="str" select="normalize-space(text()[1])"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="count(sup) > 1 and sup[1]=$insr">
							<xsl:call-template name="fix-aff-punct">
								<xsl:with-param name="str" select="normalize-space(text()[1])"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:for-each select="*[not(self::label) and not(self::sup) and not(self::bold)]|text()">
								<xsl:apply-templates select="self::node()"/>
								<xsl:text> </xsl:text>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
				</Affiliation>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="aff" mode="group-list">
		<!-- only 1 aff allowed, combine if multiple -->
		<Affiliation>
			<xsl:apply-templates/>
			<xsl:for-each select="following-sibling::aff">
				<xsl:text>; </xsl:text>
				<xsl:apply-templates/>
			</xsl:for-each>
		</Affiliation>
	</xsl:template>
	
	<xsl:template name="fix-aff-punct">
		<xsl:param name="str"/>
		<xsl:variable name="charcount" select="string-length($str)"/>
		<xsl:variable name="lastchar" select="substring($str,$charcount,1)"/>
		<xsl:choose>
			<xsl:when test="$lastchar = ':' or $lastchar = ';' or $lastchar = ','">
				<xsl:value-of select="substring($str,1,$charcount - 1)"/>
				<xsl:text>.</xsl:text>
			</xsl:when>
			<xsl:when test="$lastchar = '.' or $lastchar = '!' or $lastchar = '?'">
				<xsl:value-of select="$str"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$str"/>
				<xsl:text>.</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ==== Article front templates ==== -->
	
	<xsl:template match="xref[@ref-type='fn']"/>

	<xsl:template match="article-id[@pub-id-type='doi']">
		<ArticleId IdType="doi">
			<xsl:apply-templates/>
		</ArticleId>
	</xsl:template>

	<xsl:template match="article-id[@pub-id-type='knolid']">
		<ArticleId IdType="pii">
			<xsl:value-of select="substring-after(.,'http://knol.google.com/')"/>
		</ArticleId>
	</xsl:template>


	<xsl:template match="article-id[@pub-id-type='publisher-id']">
		<ArticleId IdType="pii">
			<xsl:apply-templates/>
		</ArticleId>
	</xsl:template>

	<xsl:template match="abstract | trans-abstract">
		<Abstract>
			<xsl:apply-templates/>
			<xsl:for-each select="ancestor::article//related-article[@related-article-type='corrected-article']">
				<xsl:call-template name="build-cx-relart"/>
			</xsl:for-each>
		</Abstract>
	</xsl:template>

	<xsl:template match="abstract/title"/>

	<!-- If citation is in abstract, strip all elements and text-dump -->
	<xsl:template match="abstract//citation">
		<xsl:apply-templates mode="notag"/>
	</xsl:template>

	<xsl:template match="sec">
		<xsl:choose>
			<xsl:when test="title ='Images'"/>
			<!-- throwing away Images sections from scanning system -->
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="sec/p">
		<xsl:choose>
			<xsl:when test="name(child::node()[1])='b'">
				<xsl:apply-templates select="child::node()[1]" mode="abs-st"/>
				<xsl:apply-templates select="child::node()[not(self::b[1])]|text()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
				<xsl:text> </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="b" mode="abs-st">
		<xsl:text> </xsl:text>
		<xsl:call-template name="capitalize">
			<xsl:with-param name="str" select="."/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="sec/title">
		<xsl:variable name="value">
			<xsl:call-template name="kill-whitespaces">
				<xsl:with-param name="str" select="."/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$value=''"/>
			<xsl:otherwise>
				<xsl:text> </xsl:text>
				<xsl:call-template name="capitalize">
					<xsl:with-param name="str" select="."/>
				</xsl:call-template>
				<xsl:choose>
					<xsl:when test="contains(.,':')">
						<xsl:text> </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>: </xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="inline-formula | disp-formula">
		<xsl:text>[Formula: see text]</xsl:text>
	</xsl:template>
	
	<xsl:template match="abstract//name/*">
		<xsl:apply-templates mode="notag"/>
		<xsl:if test="following-sibling::node()">
			<xsl:text> </xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="abstract//pub-id[@pub-id-type='pmid']"/>
	
	<xsl:template match="abstract//year">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- ==== Formatting templates ==== -->
	
	<xsl:template match="sup" mode="notag"/>
	<xsl:template match="sub" mode="notag"/>
	
	<xsl:template match="sup">
		<xsl:if test="ancestor::title-group or ancestor::abstract">
			<sup>
				<xsl:apply-templates/>
			</sup>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="sub">
		<xsl:if test="parent::article-title or parent::subtitle or ancestor::abstract">
			<inf>
				<xsl:apply-templates/>
			</inf>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="italic|bold|sc">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- ==== Miscellaneous named templates ==== -->

	<xsl:template name="get_year">
		<xsl:param name="date"/>
		<Year>
			<xsl:value-of select="substring-after(substring-after($date, '-'), '-')"/>
		</Year>
	</xsl:template>

	<xsl:template name="get_month">
		<xsl:param name="date"/>
		<Month>
			<xsl:value-of select="substring-before($date, '-')"/>
		</Month>
	</xsl:template>
	
	<xsl:template name="get_day">
		<xsl:param name="date"/>
		<Day>
			<xsl:value-of select="substring-before(substring-after($date, '-'), '-')"/>
		</Day>
	</xsl:template>

	<xsl:template name="publisher-publisher"/>
	<xsl:template name="publisher-jid"/>

	<xsl:template name="get-fpage">
		<xsl:param name="myFpage"/>
		<xsl:param name="nodes"/>
		<xsl:if test="$nodes">
			<xsl:variable name="test-fpage">
				<xsl:call-template name="stripdash">
					<xsl:with-param name="str" select="substring-before(substring-after($nodes[1],'|'),'|')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$nodes[2]">
					<xsl:call-template name="get-fpage">
						<xsl:with-param name="myFpage">
							<xsl:choose>
								<xsl:when test="$myFpage &lt; $test-fpage">
									<xsl:value-of select="$myFpage"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$test-fpage"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
						<xsl:with-param name="nodes" select="$nodes[position()!=1]"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<FirstPage>
						<xsl:choose>
							<xsl:when test="$myFpage &lt; $test-fpage">
								<xsl:value-of select="$myFpage"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$test-fpage"/>
							</xsl:otherwise>
						</xsl:choose>
					</FirstPage>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template name="get-lpage">
		<xsl:param name="myLpage"/>
		<xsl:param name="nodes"/>
		<xsl:if test="$nodes">
			<xsl:variable name="test-lpage">
				<xsl:call-template name="stripdash">
					<xsl:with-param name="str" select="substring-after(substring-after($nodes[1],'|'),'|')"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$nodes[2]">
					<xsl:call-template name="get-lpage">
						<xsl:with-param name="myLpage">
							<xsl:choose>
								<xsl:when test="$myLpage &gt; $test-lpage">
									<xsl:value-of select="$myLpage"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$test-lpage"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
						<xsl:with-param name="nodes" select="$nodes[position()!=1]"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<LastPage>
						<xsl:choose>
							<xsl:when test="$myLpage &gt; $test-lpage">
								<xsl:value-of select="$myLpage"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$test-lpage"/>
							</xsl:otherwise>
						</xsl:choose>
					</LastPage>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<!-- ==== String-editing named templates ==== -->
	
	<xsl:template name="capitalize">
		<xsl:param name="str"/>
		<xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
		<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
		<xsl:value-of select="translate($str, $lowercase, $uppercase)" />		
	</xsl:template>
	
	<!--Removes periods from a string -->
	<xsl:template name="nodot">
		<xsl:param name="str"/>
		<xsl:value-of select="translate($str,'.','')"/>
	</xsl:template>
	
	<!--Removes periods and spaces from a string -->
	<xsl:template name="cleanstring">
		<xsl:param name="str"/>
		<xsl:value-of select="translate($str, '. ', '')"/>
	</xsl:template>	
	
	<!-- Removes whitespace characters from a string -->
	<xsl:template name="kill-whitespaces">
		<xsl:param name="str"/>
		<xsl:value-of select="translate($str, ' &#x9;&#xA;&#xD;&#x20;','')"/>
	</xsl:template>
	
	<!-- Removes hyphen from a string -->
	<xsl:template name="stripdash">
		<xsl:param name="str"/>
		<xsl:value-of select="translate($str,'-','')"/>
	</xsl:template>
	
	<!-- Removes asterisk from a string -->
	<xsl:template name="remast">
		<xsl:param name="str"/>
		<xsl:value-of select="translate($str,'*','')"/>
	</xsl:template>

</xsl:stylesheet>
