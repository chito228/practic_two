// Заливка демонстрационных данных в PocketBase «Логистика».
//
// Запуск:
//   node seed.mjs
//   node seed.mjs --reset        (очистить базу и залить заново)
//
// ВАЖНО: перед запуском создайте вручную в админке PocketBase
// пользователей `logist` и `manager` с ролями logist и manager.
// Seed найдёт их по username и использует их ID для складов и задач.
//
// Все поля заполнены — Required в схеме не мешает.

const BASE = process.env.API_URL ?? 'http://127.0.0.1:8090';
const RESET = process.argv.includes('--reset');

// ───────────── Демо-данные ─────────────

const clients = [
  {
    companyName: 'ООО Логист Транс',
    contactPerson: 'Иван Иванов',
    phone: '+7-999-111-22-33',
    email: 'info@logist.ru',
    address: 'г. Москва, ул. Ленина, 1',
  },
  {
    companyName: 'ИП Петров',
    contactPerson: 'Петр Петров',
    phone: '+7-999-222-33-44',
    email: 'petrov@mail.ru',
    address: 'г. Санкт-Петербург, Невский пр., 10',
  },
  {
    companyName: 'ООО Грузовик',
    contactPerson: 'Сидор Сидоров',
    phone: '+7-999-333-44-55',
    email: 'gruzovik@yandex.ru',
    address: 'г. Казань, ул. Баумана, 5',
  },
  {
    companyName: 'ИП Смирнов',
    contactPerson: 'Алексей Смирнов',
    phone: '+7-999-444-55-66',
    email: 'smirnov@mail.ru',
    address: '',
  },
];

const cargo = [
  {
    name: 'Строительные материалы',
    description: 'Кирпич, цемент, песок',
    weightPerUnit: 50.0,
    volumePerUnit: 0.1,
  },
  {
    name: 'Электроника',
    description: 'Смартфоны, ноутбуки',
    weightPerUnit: 0.5,
    volumePerUnit: 0.01,
  },
  {
    name: 'Мебель',
    description: 'Столы, стулья, шкафы',
    weightPerUnit: 25.0,
    volumePerUnit: 0.5,
  },
];

const vehicles = [
  {
    plateNumber: 'А123ВС 777',
    driverName: 'Иванов Иван Иванович',
    capacity: 2000.0,
    status: 'active',
  },
  {
    plateNumber: 'В456УЕ 777',
    driverName: 'Петров Петр Петрович',
    capacity: 1500.0,
    status: 'active',
  },
  {
    plateNumber: 'С789ОК 777',
    driverName: 'Сидоров Сидор Сидорович',
    capacity: 3000.0,
    status: 'maintenance',
  },
];

const routes = [
  {
    name: 'Москва-Санкт-Петербург',
    origin: 'Москва',
    destination: 'Санкт-Петербург',
    distance: 700.0,
    estimatedTime: 8.0,
    status: 'active',
    vehicleIdx: 0,
  },
  {
    name: 'Москва-Казань',
    origin: 'Москва',
    destination: 'Казань',
    distance: 800.0,
    estimatedTime: 10.0,
    status: 'active',
    vehicleIdx: 1,
  },
  {
    name: 'Санкт-Петербург-Казань',
    origin: 'Санкт-Петербург',
    destination: 'Казань',
    distance: 1200.0,
    estimatedTime: 15.0,
    status: 'completed',
    vehicleIdx: 0,
  },
];

const orders = [
  {
    orderNumber: 'ORD-001',
    clientIdx: 0,
    cargoIdx: [0],
    routeIdx: [0],
    cargoDescription: 'Строительные материалы',
    weight: 1500.0,
    volume: 12.5,
    shippingDate: '2026-09-01 00:00:00.000Z',
    deliveryDate: '2026-09-05 00:00:00.000Z',
    status: 'delivered',
  },
  {
    orderNumber: 'ORD-002',
    clientIdx: 0,
    cargoIdx: [1],
    routeIdx: [1],
    cargoDescription: 'Электроника',
    weight: 350.0,
    volume: 3.2,
    shippingDate: '2026-09-03 00:00:00.000Z',
    deliveryDate: '',
    status: 'in_transit',
  },
  {
    orderNumber: 'ORD-003',
    clientIdx: 1,
    cargoIdx: [2],
    routeIdx: [0],
    cargoDescription: 'Мебель',
    weight: 800.0,
    volume: 8.0,
    shippingDate: '2026-08-28 00:00:00.000Z',
    deliveryDate: '2026-08-30 00:00:00.000Z',
    status: 'delivered',
  },
  {
    orderNumber: 'ORD-004',
    clientIdx: 2,
    cargoIdx: [0, 1],
    routeIdx: [2],
    cargoDescription: 'Продукты питания',
    weight: 2000.0,
    volume: 15.0,
    shippingDate: '2026-09-01 00:00:00.000Z',
    deliveryDate: '',
    status: 'in_transit',
  },
  {
    orderNumber: 'ORD-005',
    clientIdx: 2,
    cargoIdx: [2],
    routeIdx: [1],
    cargoDescription: 'Запасные части',
    weight: 120.0,
    volume: 1.5,
    shippingDate: '2026-08-25 00:00:00.000Z',
    deliveryDate: '',
    status: 'cancelled',
  },
];

// У ВСЕХ складов заполнены manager и cargo.
const warehouses = [
  {
    name: 'Склад №1 «Москва-Север»',
    address: 'г. Москва, ул. Ленина, 1',
    type: 'dry',
    capacity: 1000.0,
    currentLoad: 850.0,
    managerUser: 'logist',
    cargoIdx: [0, 2],
    routeIdx: [0, 1],
  },
  {
    name: 'Склад №2 «Казань-Центр»',
    address: 'г. Казань, ул. Баумана, 5',
    type: 'cold',
    capacity: 500.0,
    currentLoad: 480.0,
    managerUser: 'logist',
    cargoIdx: [1],
    routeIdx: [1, 2],
  },
  {
    name: 'Склад №3 «СПб-Порт»',
    address: 'г. Санкт-Петербург, Невский пр., 10',
    type: 'hazardous',
    capacity: 2000.0,
    currentLoad: 350.0,
    // manager заполнен — используем manager вместо пустого значения
    managerUser: 'manager',
    cargoIdx: [0],
    routeIdx: [0, 2],
  },
];

// У ВСЕХ задач заполнены order и route.
const tasks = [
  {
    title: 'Проверить маршрут Москва-Казань',
    description:
      'Маршрут показывает аномально высокое расчётное время. Проверить данные.',
    priority: 'high',
    status: 'new',
    createdByUser: 'manager',
    assignedToUser: 'logist',
    // order заполнен — берём ORD-001 (индекс 0)
    orderIdx: 0,
    // route заполнен — Москва-Казань (индекс 1)
    routeIdx: 1,
    dueDate: '2026-09-20 00:00:00.000Z',
    resolution: '',
  },
  {
    title: 'Сверить вес груза ORD-002',
    description: 'Вес в заказе не совпадает с данными склада.',
    priority: 'medium',
    status: 'in_progress',
    createdByUser: 'manager',
    assignedToUser: 'logist',
    orderIdx: 1,     // ORD-002
    routeIdx: 1,     // Москва-Казань
    dueDate: '2026-09-25 00:00:00.000Z',
    resolution: '',
  },
  {
    title: 'Обновить данные по складу №3',
    description: 'Склад пустой, но числится в маршрутах. Уточнить статус.',
    priority: 'low',
    status: 'done',
    createdByUser: 'manager',
    assignedToUser: 'logist',
    orderIdx: 4,     // ORD-005
    routeIdx: 0,     // Москва-Санкт-Петербург
    dueDate: '2026-09-15 00:00:00.000Z',
    resolution: 'Данные обновлены, склад активен.',
  },
];

// ───────────── HTTP-обвязка ─────────────

async function request(method, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text();
    const hint =
      res.status === 403
        ? '\n\nПохоже, у коллекции закрыты правила доступа. Откройте админку,\n' +
          'вкладку API Rules нужной коллекции и снимите замок со всех пяти\n' +
          'правил (List/Search, View, Create, Update, Delete), оставив поля пустыми.'
        : '';
    throw new Error(`${method} ${path} → ${res.status}\n${text}${hint}`);
  }

  const text = await res.text();
  return text ? JSON.parse(text) : null;
}

const create = (collection, body) =>
  request('POST', `/api/collections/${collection}/records`, body);

async function listAll(collection) {
  const items = [];
  let page = 1;
  for (;;) {
    const chunk = await request(
      'GET',
      `/api/collections/${collection}/records?perPage=200&page=${page}`,
    );
    items.push(...chunk.items);
    if (page >= chunk.totalPages) break;
    page += 1;
  }
  return items;
}

async function findUserId(username) {
  const page = await request(
    'GET',
    `/api/collections/users/records?filter=(username = "${username}")&perPage=1`,
  );
  if (page.totalItems === 0) {
    throw new Error(
      `Пользователь «${username}» не найден. ` +
        `Создайте его вручную через админку PocketBase ` +
        `(Collections → users → + New record), ` +
        `затем снова запустите seed.`,
    );
  }
  return page.items[0].id;
}

async function clearAll() {
  const order = [
    'tasks',
    'orders',
    'warehouses',
    'routes',
    'vehicles',
    'cargo',
    'clients',
  ];
  for (const collection of order) {
    const items = await listAll(collection);
    for (const item of items) {
      await request(
        'DELETE',
        `/api/collections/${collection}/records/${item.id}`,
      );
    }
    console.log(`Очищено ${collection}: ${items.length}`);
  }
}

async function isEmpty(collection) {
  const page = await request(
    'GET',
    `/api/collections/${collection}/records?perPage=1`,
  );
  return page.totalItems === 0;
}

// ───────────── Заливка ─────────────

async function main() {
  console.log(`Сервер: ${BASE}`);

  if (RESET) {
    await clearAll();
  } else if (!(await isEmpty('clients'))) {
    console.log('В базе уже есть данные.');
    console.log('Запустите с ключом --reset, чтобы очистить их и залить заново.');
    return;
  }

  // 1. Клиенты
  const clientIds = [];
  for (const c of clients) {
    const r = await create('clients', c);
    clientIds.push(r.id);
  }
  console.log(`Клиенты: ${clientIds.length}`);

  // 2. Грузы
  const cargoIds = [];
  for (const g of cargo) {
    const r = await create('cargo', g);
    cargoIds.push(r.id);
  }
  console.log(`Грузы: ${cargoIds.length}`);

  // 3. Транспорт
  const vehicleIds = [];
  for (const v of vehicles) {
    const r = await create('vehicles', v);
    vehicleIds.push(r.id);
  }
  console.log(`Транспорт: ${vehicleIds.length}`);

  // 4. Маршруты
  const routeIds = [];
  for (const r of routes) {
    const { vehicleIdx, ...rest } = r;
    const rec = await create('routes', {
      ...rest,
      vehicle: vehicleIds[vehicleIdx],
    });
    routeIds.push(rec.id);
  }
  console.log(`Маршруты: ${routeIds.length}`);

  // 5. Заказы
  const orderIds = [];
  for (const o of orders) {
    const { clientIdx, cargoIdx, routeIdx, ...rest } = o;
    const rec = await create('orders', {
      ...rest,
      client: clientIds[clientIdx],
      cargo: cargoIdx.map((i) => cargoIds[i]),
      routes: routeIdx.map((i) => routeIds[i]),
    });
    orderIds.push(rec.id);
  }
  console.log(`Заказы: ${orderIds.length}`);

  // 6. Пользователи
  const logistId = await findUserId('logist');
  const managerId = await findUserId('manager');
  console.log(`Пользователи: logist=${logistId}, manager=${managerId}`);

  // 7. Склады (все поля заполнены)
  for (const w of warehouses) {
    const { managerUser, cargoIdx, routeIdx, ...rest } = w;
    const manager = managerUser === 'logist' ? logistId : managerId;
    await create('warehouses', {
      ...rest,
      manager: manager,
      cargo: cargoIdx.map((i) => cargoIds[i]),
      routes: routeIdx.map((i) => routeIds[i]),
    });
  }
  console.log(`Склады: ${warehouses.length}`);

  // 8. Задачи (все поля заполнены)
  for (const t of tasks) {
    const {
      orderIdx,
      routeIdx,
      createdByUser,
      assignedToUser,
      ...rest
    } = t;
    const createdBy = createdByUser === 'manager' ? managerId : logistId;
    const assignedTo = assignedToUser === 'logist' ? logistId : managerId;
    await create('tasks', {
      ...rest,
      createdBy: createdBy,
      assignedTo: assignedTo,
      order: orderIds[orderIdx],
      route: routeIds[routeIdx],
    });
  }
  console.log(`Задачи: ${tasks.length}`);

  console.log('Готово.');
}

main().catch((error) => {
  console.error('Не получилось:');
  console.error(error.message);
  process.exitCode = 1;
});
