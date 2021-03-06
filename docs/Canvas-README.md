#Canvas support

## Canvas maintenance Rake tasks

When on a Torquebox-enabled shared servers, be sure to `cd deploy` before running any Rake or Rails command.

* `RAILS_ENV=production bundle exec rake canvas:full_refresh`
    1. Request Canvas reports for all user accounts, and all course sections for every current term.
    2. Download the reports.
    3. Check all existing user accounts against campus data, change their SIS IDs as needed, and append any other account changes to a "users" CSV file.
    4. Append each section's current student enrollments and official list of instructors to a term-specific "enrollments" CSV file.
    5. Add any new student or instructor accounts to the "users" CSV file.
    6. Upload the "users" CSV file to Canvas.
    7. Upload each term's "enrollments" CSV to Canvas as a batch update, replacing all the previously imported student and instructor assignments for the term.
* `RAILS_ENV=production bundle exec rake canvas:repair_course_sis_ids TERM_ID='TERM:2013-C'`

    Our current integration scheme links a Canvas Course Section's SIS ID to the ID of an official section in campus systems. E.g., a Canvas Section whose sis_id was `SEC:2013-C-7309` would draw enrollments and instructors from CCN 7309 Summer 2013. For imports to work, the section's Canvas Course must have _some_ SIS ID, but what it is doesn't matter (for now). This task is an administrative convenience so that we don't manually have to come up with Course SIS IDs.
    1. Request a Canvas report on the sections of the specified term.
    2. Download the report.
    3. For each Course which has an SIS-integrated Section, but which has no SIS ID (or an otherwise improper SIS ID), write a good SIS ID to the Course.

## Canvas maintenance shell scripts

* `script/reconfigure-canvas-external-apps.sh`

    Checks bCourses test/beta for overwritten external app configurations, and resets them if needed.
    Before running, two environment variables must be set:
    * `CALCENTRAL_XML_HOST` : URL root of a CalCentral server which is accessible from the bCourses machines.

        Example:
        `CALCENTRAL_XML_HOST='https://calcentral.example.com'`
    * `CANVAS_HOSTS_TO_CALCENTRALS` : Mapping from the bCourses test/beta servers to their assigned CalCentral app hosts.

        Example:
        `CANVAS_HOSTS_TO_CALCENTRALS='https://ucb.beta.example.com=cc-dev.example.com,https://ucb.test.example.com=cc-qa.example.com'`
* `script/refresh-canvas-enrollments.sh`

    Runs `rake canvas:full_refresh` with `RAILS_ENV=production`.

## Canvas embedded tools

* XML configuration for Rosters app
Sets the app to show up as a Course site tool, visible to teachers and admins, and sending parameters to describe the current user and site context. Generated by [Instructure's XML Config builder](http://www.edu-apps.org/build_xml.html):

```
<?xml version="1.0" encoding="UTF-8"?>
<cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
    xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
    xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
    xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
    xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
    http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
    http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
    <blti:title>Roster Photos</blti:title>
    <blti:description>Browse and search official roster photos</blti:description>
    <blti:icon></blti:icon>
    <blti:launch_url>http://localhost:3000/canvas/embedded/rosters</blti:launch_url>
    <blti:extensions platform="canvas.instructure.com">
      <lticm:property name="tool_id">calcentral_rosters</lticm:property>
      <lticm:property name="privacy_level">public</lticm:property>
      <lticm:options name="course_navigation">
        <lticm:property name="url">http://localhost:3000/canvas/embedded/rosters</lticm:property>
        <lticm:property name="text">Roster Photos</lticm:property>
        <lticm:property name="visibility">admins</lticm:property>
        <lticm:property name="default">enabled</lticm:property>
        <lticm:property name="enabled">true</lticm:property>
      </lticm:options>
    </blti:extensions>
    <cartridge_bundle identifierref="BLTI001_Bundle"/>
    <cartridge_icon identifierref="BLTI001_Icon"/>
</cartridge_basiclti_link>
```

### Dependencies

Canvas is configured on the account level to include [Javascript](../public/canvas/canvas-customization.js) and [CSS](../public/canvas/canvas-skin.css) from the CalCentral server. Some modifications to the Canvas user interface are being made by the Javascript included within Canvas. Please note the following:

* A modification is made to the 'Add People' button displayed on the 'People' section within a Canvas course site. This button is replaced with a link to the 'Add People' LTI application. This modification [requires](../public/canvas/canvas-customization.js#L13) that the 'Add People' LTI application is [configured to display](../app/views/canvas_lti/lti_course_add_user.xml.erb#L20) with the text 'Add People' in the course navigation menu.
* A modification is made to the 'Start a New Course' button displayed on the right sidebar of the Canvas dashboard and Canvas courses index page. This button is replaced with the text 'Create a Course Site', and is instead linked to the Course Provisioning LTI application. This modification [requires](../public/canvas/canvas-customization.js#L45) that the LTI application is configured in the Canvas Account Settings with the name 'Course Provisioning for Users'. The name of the LTI application is decided by the Canvas Account Administrator when configuring the LTI application. If the name provided by the [external_tools.json](../config/routes.rb#L51) does not match this, the logic for the button replacement will not work.


