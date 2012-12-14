<?xml version="1.0"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
  xmlns:fr="http://www.crossref.org/fundref.xsd" 
  xmlns="http://www.crossref.org/schema/4.3.1" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <!-- 
    pmc2crossref.xsl
    =============================================================
    This stylesheet is intended for converting PMC-compliant JATS
    XML to crossref format for submission to doi.crossref.org. It
    creates only the <body> element. <head> is a required element
    and must be added by the depositor.
    =============================================================
    2012/12/13
  -->

  <xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>

  <xsl:template match="/">
    <xsl:if test="/article">
      <doi_batch xsi:schemaLocation="http://www.crossref.org/schema/4.3.1 file:http://www.crossref.org/schema/deposit/crossref4.3.1.xsd">
        <!-- Insert <head> here-->
        <!--<head>
          <doi_batch_id>doi_batch_id0</doi_batch_id>
          <timestamp>0</timestamp>
          <depositor>
            <name>name0</name>
            <email_address>!@!.-\-</email_address>
          </depositor>
          <registrant>registrant0</registrant>
        </head>-->
        <body>
          <xsl:apply-templates/>
        </body>
      </doi_batch>
    </xsl:if>
  </xsl:template>

  <xsl:template match="/article">
    <xsl:if test="string-length(front/article-meta/article-id[@pub-id-type='doi']) &gt; 0">
      <journal>
        <journal_metadata>
          <xsl:call-template name="fulltitle"/>
          <xsl:apply-templates select="front/journal-meta/journal-id[@journal-id-type='nlm-ta']"/>
          <xsl:apply-templates select="front/journal-meta/issn"/>
        </journal_metadata>
        <xsl:call-template name="build-issue"/>
        <xsl:call-template name="build-article"/>
      </journal>
    </xsl:if>
  </xsl:template>

  <xsl:template name="build-issue">
    <journal_issue>
      <xsl:call-template name="publication-date"/>
      <xsl:apply-templates select="front/article-meta/volume"/>
      <xsl:choose>
        <xsl:when test="front/article-meta/issue">
          <xsl:apply-templates select="front/article-meta/issue"/>
        </xsl:when>
        <xsl:when test="front/article-meta/pub-date[@pub-type='ppub']">
          <xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']" mode="issue"/>
        </xsl:when>
        <xsl:when test="front/article-meta/pub-date[@pub-type='epub']">
          <xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']" mode="issue"/>
        </xsl:when>
      </xsl:choose>
    </journal_issue>
  </xsl:template>

  <xsl:template name="build-article">
    <journal_article publication_type="full_text">
      <xsl:choose>
        <xsl:when test="front/article-meta/title-group">
          <xsl:apply-templates select="front/article-meta/title-group"/>
        </xsl:when>
        <xsl:when test="front/article-meta/article-categories/subj-group[1]">
          <xsl:apply-templates select="front/article-meta/article-categories/subj-group[1]"/>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
      <xsl:call-template name="build-contributors"/>
      <xsl:call-template name="publication-date"/>
      <pages>
        <xsl:apply-templates select="front/article-meta/fpage"/>
        <xsl:apply-templates select="front/article-meta/elocation-id"/>
        <xsl:apply-templates select="front/article-meta/lpage"/>
      </pages>
      <xsl:for-each select="front/article-meta/article-id[@pub-id-type='doi']">
        <publisher_item>
          <item_number item_number_type="sequence-number">
            <xsl:apply-templates/>
          </item_number>
        </publisher_item>
      </xsl:for-each>
      <doi_data>
        <doi>
          <xsl:value-of select="front/article-meta/article-id[@pub-id-type='doi']"/>
        </doi>
        <resource>
          <xsl:value-of select="concat('http://dx.doi.org/', front/article-meta/article-id[@pub-id-type='doi'])"/>
        </resource>
      </doi_data>
    </journal_article>
  </xsl:template>

  <xsl:template name="publication-date">
    <xsl:choose>
      <xsl:when test="front/article-meta/pub-date[@pub-type='ppub']">
        <publication_date media_type="print">
          <xsl:apply-templates select="front/article-meta/pub-date[@pub-type='ppub']"/>
        </publication_date>
      </xsl:when>
      <xsl:when test="front/article-meta/pub-date[@pub-type='epub']">
        <publication_date media_type="online">
          <xsl:apply-templates select="front/article-meta/pub-date[@pub-type='epub']"/>
        </publication_date>
      </xsl:when>
      <xsl:when test="front/article-meta/pub-date">
        <publication_date media_type="other">
          <xsl:apply-templates select="front/article-meta/pub-date"/>
        </publication_date>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  

  <!-- ==== Title Templates ==== -->
  <xsl:template name="fulltitle">
    <full_title>
      <xsl:choose>
        <xsl:when test="front/journal-meta/journal-title">
          <xsl:value-of select="front/journal-meta/journal-title"/>
        </xsl:when>
        <xsl:when test="front/journal-meta/journal-title-group/journal-title">
          <xsl:value-of select="front/journal-meta/journal-title-group/journal-title"/>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </full_title>
  </xsl:template>

  <xsl:template match="title-group|subj-group">
    <titles>
      <title>
        <xsl:apply-templates select="article-title | subtitle | subject"/>
      </title>
    </titles>
  </xsl:template>


  <!-- ==== Author Templates ==== -->
  <xsl:template name="build-contributors">
    <xsl:variable name="_contributors">
      <xsl:apply-templates select="front/article-meta/contrib-group"/>
    </xsl:variable>
    <xsl:if test="string-length($_contributors)">
      <contributors>
        <xsl:copy-of select="$_contributors"/>
      </contributors>
    </xsl:if>
  </xsl:template>

  <xsl:template match="contrib-group[position() = 1]">
    <xsl:for-each select="contrib[(count(name/given-names) + count(name/surname)) &gt; 0]">
      <xsl:choose>
        <xsl:when test="position() = 1">
          <xsl:apply-templates select="." mode="au1"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="contrib-group[position() &gt; 1]">
    <xsl:for-each select="contrib[(count(name/given-names) + count(name/surname)) &gt; 0]">
      <xsl:apply-templates select="."/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="contrib" mode="au1">
    <xsl:if test="name/given-names or name/surname">
      <person_name sequence="first" contributor_role="{@contrib-type}">
        <xsl:apply-templates select="name/given-names"/>
        <xsl:apply-templates select="name/surname"/>
      </person_name>
    </xsl:if>
  </xsl:template>

  <xsl:template match="contrib[name/given-names or name/surname]">
    <xsl:if test="name/given-names or name/surname">
      <person_name sequence="additional" contributor_role="{@contrib-type}">
        <xsl:apply-templates select="name/given-names"/>
        <xsl:apply-templates select="name/surname"/>
      </person_name>
    </xsl:if>
  </xsl:template>

  <xsl:template match="collab"/>
  <xsl:template match="given-names">
    <xsl:if test="string-length(.) &gt; 0">
      <given_name>
        <xsl:apply-templates/>
      </given_name>
    </xsl:if>
  </xsl:template>

  <xsl:template match="surname">
    <surname>
      <xsl:apply-templates/>
    </surname>
  </xsl:template>

  <!-- ==== Enumeration templates ==== -->
  <xsl:template match="volume">
    <journal_volume>
      <volume>
        <xsl:apply-templates/>
      </volume>
    </journal_volume>
  </xsl:template>

  <xsl:template match="issue">
    <xsl:if test="string-length(.) &lt; 16">
      <issue>
        <xsl:apply-templates/>
      </issue>
    </xsl:if>
  </xsl:template>

  <xsl:template match="pub-date" mode="issue">
    <xsl:if test="season and string-length(season) &lt; 16">
      <issue>
        <xsl:apply-templates select="season"/>
      </issue>
    </xsl:if>
  </xsl:template>

  <xsl:template match="pub-date">
    <xsl:if test="month">
      <month>
        <xsl:value-of select="month"/>
      </month>
    </xsl:if>
    <xsl:if test="day">
      <day>
        <xsl:value-of select="day"/>
      </day>
    </xsl:if>
    <xsl:if test="year">
      <year>
        <xsl:value-of select="year"/>
      </year>
    </xsl:if>
  </xsl:template>

  <xsl:template match="fpage | elocation-id">
    <first_page>
      <xsl:apply-templates/>
    </first_page>
  </xsl:template>

  <xsl:template match="lpage">
    <last_page>
      <xsl:apply-templates/>
    </last_page>
  </xsl:template>

  <!-- ==== Journal Templates ==== -->

  <xsl:template match="journal-id">
    <abbrev_title>
      <xsl:apply-templates/>
    </abbrev_title>
  </xsl:template>

  <xsl:template match="issn">
    <xsl:if test="@pub-type='epub'">
      <issn media_type="electronic">
        <xsl:apply-templates/>
      </issn>
    </xsl:if>
    <xsl:if test="@pub-type='ppub'">
      <issn media_type="print">
        <xsl:apply-templates/>
      </issn>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xref"/>
</xsl:stylesheet>
