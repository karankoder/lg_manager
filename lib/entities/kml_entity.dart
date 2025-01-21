class KMLEntity {
  String name;
  String content;
  String screenOverlay;

  KMLEntity({
    required this.name,
    required this.content,
    this.screenOverlay = '',
  });

  String get body => '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>$name</name>
    <open>1</open>
    <Folder>
      $content
      $screenOverlay
    </Folder>
  </Document>
</kml>
  ''';
  static String generateBlank(String id) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document id="$id">
  </Document>
</kml>
    ''';
  }

  static String generateLinearString(
      String lng, String lat, String range, String tilt, String heading) {
    return '<LookAt><longitude>$lng</longitude><latitude>$lat</latitude><range>$range</range><tilt>$tilt</tilt><heading>$heading</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>';
  }

  static String orbitBalloon(
    String cityImage,
  ) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
<Document>
 <name>About Data</name>
 <Style id="about_style">
   <BalloonStyle>
     <textColor>ffffffff</textColor>
     <text>
        <h1>Karan Kumar Das</h1>
        <h1>Kolkata</h1>
        <img src="$cityImage" alt="City" width="300" height="200" />
     </text>
     <bgColor>ff15151a</bgColor>
   </BalloonStyle>
 </Style>
 <Placemark id="ab">
   <description>
   </description>
   <LookAt>
  <longitude>88.3639</longitude><latitude>22.5726</latitude>
     <heading>0</heading>
     <tilt>0</tilt>
     <range>200</range>
   </LookAt>
   <styleUrl>#about_style</styleUrl>
   <gx:balloonVisibility>1</gx:balloonVisibility>
   <Point>
     <coordinates>88.3639,22.5726,0</coordinates>
   </Point>
 </Placemark>
</Document>
</kml>''';
  }

  static String newKML() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Static Beauty - Delhi</name>
    <Style id="fancyPlacemark">
      <IconStyle>
        <color>ff00ffff</color> <!-- Cyan icon -->
        <scale>1.5</scale>
        <Icon>
          <href>https://maps.google.com/mapfiles/kml/shapes/star.png</href>
        </Icon>
      </IconStyle>
      <LabelStyle>
        <color>ffffaa00</color> <!-- Golden label -->
        <scale>1.2</scale>
      </LabelStyle>
    </Style>
    <Style id="colorfulPolygon">
      <PolyStyle>
        <color>7dff0000</color> <!-- Semi-transparent red -->
        <outline>1</outline>
      </PolyStyle>
      <LineStyle>
        <color>ff0000ff</color> <!-- Blue outline -->
        <width>2</width>
      </LineStyle>
    </Style>
    <Placemark>
      <name>Peaceful Point</name>
      <description>A serene location for relaxation in Delhi.</description>
      <styleUrl>#fancyPlacemark</styleUrl>
      <Point>
        <coordinates>77.2090,28.6139,0</coordinates> <!-- Delhi, India -->
      </Point>
    </Placemark>
    <Placemark>
      <name>Artistic Area</name>
      <description>A colorful polygon to enhance this location.</description>
      <styleUrl>#colorfulPolygon</styleUrl>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              77.2085,28.6135,0
              77.2095,28.6135,0
              77.2095,28.6143,0
              77.2085,28.6143,0
              77.2085,28.6135,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>
''';
  }
}
