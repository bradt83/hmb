import 'package:june/june.dart';
import 'package:money2/money2.dart';
import 'package:sqflite/sqflite.dart';
import 'package:strings/strings.dart';

import '../entity/customer.dart';
import '../entity/job.dart';
import 'dao.dart';
import 'dao_system.dart';

class DaoCustomer extends Dao<Customer> {
  Future<void> createTable(Database db, int version) async {}

  @override
  Customer fromMap(Map<String, dynamic> map) => Customer.fromMap(map);

  @override
  String get tableName => 'customer';

  /// Get the customer passed on the passed job.
  Future<Customer?> getByJob(Job? job) async {
    final db = getDb();

    if (job == null) {
      return null;
    }
    final data = await db.rawQuery('''
select c.* 
from job j
join customer c
  on c.id = job.customer_id
where j.id =? 
''', [job.id]);

    return toList(data).first;
  }

  Future<List<Customer>> getByFilter(String? filter) async {
    final db = getDb();

    if (Strings.isBlank(filter)) {
      return getAll();
    }
    final data = await db.rawQuery('''
select c.* 
from customer c
where c.name like ?
''', ['''%$filter%''']);

    return toList(data);
  }

  Future<Money> getHourlyRate(int customerId) async {
    final customer = await getById(customerId);

    Money hourlyRate;
    if (customer?.hourlyRate == null) {
      hourlyRate = (await DaoSystem().get())?.defaultHourlyRate ??
          Money.fromInt(0, isoCode: 'AUD');
    } else {
      hourlyRate = customer?.hourlyRate ?? Money.fromInt(0, isoCode: 'AUD');
    }
    return hourlyRate;
  }

  @override
  JuneStateCreator get juneRefresher => CustomerState.new;
}

/// Used to notify the UI that the time entry has changed.
class CustomerState extends JuneState {
  CustomerState();
}
