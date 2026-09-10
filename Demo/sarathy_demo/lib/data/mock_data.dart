import 'package:flutter/material.dart';
import '../models/models.dart';

class MockData {
  static const locations = [
    DemoLocation('Aluva', 'ALV', 'Gateway to Kochi', Color(0xff3977e8)),
    DemoLocation('Kochi', 'KOC', 'The Queen of Arabian Sea', Color(0xffff7b45)),
    DemoLocation(
      'Thiruvananthapuram',
      'TRV',
      'The capital city',
      Color(0xff21a179),
    ),
  ];
  static final Map<String, List<DemoBus>> buses = {
    'Aluva': _make(
      '10',
      [
        'Aluva – Fort Kochi',
        'Aluva – Kakkanad',
        'Aluva – Vytilla',
        'Aluva – Airport',
        'Aluva – Edappally',
      ],
      [
        'Fort Kochi',
        'Kakkanad',
        'Vytilla Hub',
        'Airport Terminal',
        'Edappally',
      ],
      locations[0],
    ),
    'Kochi': _make(
      '20',
      [
        'Vytilla – Fort Kochi',
        'Kakkanad – Vytilla',
        'Edappally – Mattancherry',
        'Kaloor – Tripunithura',
        'Willingdon – Aluva',
      ],
      ['Fort Kochi', 'Vytilla Hub', 'Mattancherry', 'Tripunithura', 'Aluva'],
      locations[1],
    ),
    'Thiruvananthapuram': _make(
      '30',
      [
        'East Fort – Kazhakkoottam',
        'Kowdiar – Vizhinjam',
        'Pattom – Neyyattinkara',
        'Vazhuthacaud – Technopark',
        'Peroorkada – East Fort',
      ],
      [
        'Kazhakkoottam',
        'Vizhinjam',
        'Neyyattinkara',
        'Technopark',
        'East Fort',
      ],
      locations[2],
    ),
  };
  static List<DemoBus> _make(
    String prefix,
    List<String> routes,
    List<String> destinations,
    DemoLocation location,
  ) => List.generate(
    5,
    (i) => DemoBus(
      id: 'Sarathy $prefix${i + 1}',
      route: routes[i],
      destination: destinations[i],
      eta: ['4 min', '8 min', '12 min', '18 min', '24 min'][i],
      speed: [22, 18, 26, 14, 20][i].toDouble(),
      status: i == 1 ? BusStatus.approaching : BusStatus.onTime,
      confidence: [.94, .88, .91, .76, .84][i],
      nextStop: [
        'Companypady',
        'Kalamassery',
        'Aluva Metro',
        'Choondy',
        'UC College',
      ][i],
      stopsRemaining: 3 + i,
      color: location.color,
      progress: .34 + i * .1,
    ),
  );
  static const stops = [
    DemoStop('Aluva Metro Station', '0.4 km', '5 buses', '4 min', 'Aluva'),
    DemoStop('Vytilla Mobility Hub', '1.2 km', '8 buses', '3 min', 'Kochi'),
    DemoStop('Kakkanad Civil Station', '2.8 km', '4 buses', '8 min', 'Kochi'),
    DemoStop('East Fort', '0.9 km', '6 buses', '5 min', 'Thiruvananthapuram'),
    DemoStop(
      'Kowdiar Junction',
      '1.6 km',
      '3 buses',
      '9 min',
      'Thiruvananthapuram',
    ),
    DemoStop('Companypady', '1.9 km', '2 buses', '12 min', 'Aluva'),
  ];
  static const notifications = [
    DemoNotification(
      'Sarathy 201 is approaching',
      'Your bus to Fort Kochi is arriving at Vytilla Mobility Hub.',
      '2 min ago',
      Icons.notifications_active_rounded,
      Color(0xffff7b45),
    ),
    DemoNotification(
      'Traffic on Marine Drive',
      'Expect a 6–8 minute delay on routes towards Fort Kochi.',
      '18 min ago',
      Icons.traffic_rounded,
      Color(0xff3977e8),
    ),
    DemoNotification(
      'Trip reminder',
      'Your saved trip to Kakkanad starts in 20 minutes.',
      '1 hr ago',
      Icons.route_rounded,
      Color(0xff21a179),
    ),
    DemoNotification(
      'Service announcement',
      'Sarathy is adding new late-evening services this month.',
      'Yesterday',
      Icons.campaign_rounded,
      Color(0xff7b61ff),
      unread: false,
    ),
  ];
}
