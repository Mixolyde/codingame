import '../bin/codersstrikeback.dart';
import 'package:test/test.dart';

void main() {  
  group('dart math', (){
    test('truncate', (){
      expect((2.1).truncate(), 2);
      expect((2.9).truncate(), 2);
      expect((-2.1).truncate(), -2);
      expect((-2.9).truncate(), -2);      
    });
  });
  group('pods:', () {
    test('new pod', () {
      Pod a = new Pod(0, 1, 2, 3, 4, 5, 6);
      expect(a.id, 0);
      expect(a.x, 1);
      expect(a.y, 2);
      expect(a.vx, 3);
      expect(a.vy, 4);
      expect(a.angle, 5);
      expect(a.nextCP, 6);
      expect(a.radius, 400);
      expect(a.timeout, 100);
      expect(a.shield, false);
      expect(a.shieldTimeout, 0);
      expect(a.checked, 0);
      expect(a.boostUsed, false);
      
    });
    test('clone pods', () {
      Pod a = new Pod(0, 0, 0, 0, 0, 0, 0);
      a.timeout = 50;
      a.shield = false;
      Pod b = a.clone();
      expect(a.timeout, b.timeout);
      expect(a.shield, b.shield);
      expect(a.id , b.id);
      a.timeout = 0;
      expect(a.timeout, equals(00));
      expect(b.timeout, equals(50));
    });
    test('get angles', () {
      Pod a = new Pod(0, 0, 0, 0, 0, 0, 0);

      expect(a.getAngle(new Point(5,0)), 0);
      expect(a.getAngle(new Point(-5,0)), 180);
      expect(a.getAngle(new Point(0,5)), 90);
      expect(a.getAngle(new Point(0,-5)), 270);
    });
    test('diff angles', () {
      Pod a = new Pod(0, 0, 0, 0, 0, 0, 0);

      expect(a.diffAngle(new Point(5,0)), 0);
      expect(a.diffAngle(new Point(-5,0)), -180);
      expect(a.diffAngle(new Point(0,5)), 90);
      expect(a.diffAngle(new Point(0,-5)), -90);
    });
    test('rotate angles', () {
      Pod a = new Pod(0, 0, 0, 0, 0, 0, 0);

      a.rotate(new Point(5, 0));
      expect(a.angle, 0);

      a.rotate(new Point(5, 5));
      expect(a.angle, 18);

      a.angle = 0;
      a.rotate(new Point(5, -5));
      expect(a.angle, 360 - 18);
    });
  });
  group('checkpoints:', () {
    test('new cp', () {
      Checkpoint a = new Checkpoint(1, 4, 5);
      expect(a.id, 1);
      expect(a.x, 4);
      expect(a.y, 5);
      expect(a.vx, 0);
      expect(a.vy, 0);      
      expect(a.radius, 200);
    });
  });
  group('collisions:', (){
    test('no collision', (){
      Pod a= new Pod(0, 0, 0, 0, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 601, 0);

      Collision? col = a.collision(cp);
      expect(col, null);

    });
    test('t=0 collision', (){
      Pod a= new Pod(0, 0, 0, 0, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 599, 0);

      Collision? col = a.collision(cp);
      expect(col, isNotNull);
      expect(col!.t, 0);

    });
    test('t=0.5 collision', (){
      Pod a= new Pod(0, 0, 0, 1000, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 1100, 0);

      Collision? col = a.collision(cp);
      expect(col, isNotNull);
      expect(col!.t, 0.5);

    });
    test('t=0.5 collision at angle', (){
      Pod a= new Pod(0, 0, 0, 1000, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 500, 599.999);

      Collision? col = a.collision(cp);
      expect(col, isNotNull);
      expect(col!.t, lessThanOrEqualTo(0.5));
      expect(col.t, greaterThanOrEqualTo(0.47));

    });
    test('moving wrong way', (){
      Pod a= new Pod(0, 0, 0, -1000, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 500, -599.99);

      Collision? col = a.collision(cp);
      expect(col, null);

    });
    test('not fast enough', (){
      Pod a= new Pod(0, 0, 0, 100, 0, 0, 0);

      Checkpoint cp = new Checkpoint(1, 500, -599.99);

      Collision? col = a.collision(cp);
      expect(col, null);

    });


  });
}
