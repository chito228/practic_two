#!/usr/bin/env node
/**
 * Мок-сервер учебного API «Логистика».
 *
 *   node mock-server.js
 *   node mock-server.js --port 8080 --origin http://localhost:5555
 *
 * Данные хранятся в памяти и сбрасываются при перезапуске
 * либо запросом POST /api/__reset
 *
 * Учебные возможности:
 *   ?__delay=1500   задержка ответа в миллисекундах
 *   ?__fail=500     принудительный код ошибки
 */

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');

// ─────────────────────────── параметры запуска ───────────────────────────

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', '*');
const SECRET = 'учебный-ключ-не-для-продакшена';
const ACCESS_TTL = Number(arg('ttl', 900));
const REFRESH_TTL = 60 * 60 * 24 * 7;

// ─────────────────────────────── токены ───────────────────────────────

function b64url(buf) {
  return Buffer.from(buf).toString('base64url');
}

function sign(payload) {
  const withId = { ...payload, jti: crypto.randomUUID() };
  const body = b64url(JSON.stringify(withId));
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, mac] = token.split('.');
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (mac !== expected) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp * 1000 < Date.now()) return null;
  return payload;
}

// ─────────────────────────────── данные ───────────────────────────────

let db;

function seed() {
  db = {
    seq: {},
    clients: [],
    orders: [],
    cargo: [],
    routes: [],
    vehicles: [],
    users: [],
    refreshTokens: new Set(),
  };

  // ─── Клиенты ───
  const C = (companyName, contactPerson, phone, email, address) =>
    push('clients', { companyName, contactPerson, phone, email, address: address || null });

  const c1 = C('ООО Логист Транс', 'Иван Иванов', '+7-999-111-22-33', 'info@logist.ru', 'г. Москва, ул. Ленина, 1');
  const c2 = C('ИП Петров', 'Петр Петров', '+7-999-222-33-44', 'petrov@mail.ru', 'г. Санкт-Петербург, Невский пр., 10');
  const c3 = C('ООО Грузовик', 'Сидор Сидоров', '+7-999-333-44-55', 'gruzovik@yandex.ru', 'г. Казань, ул. Баумана, 5');
  const c4 = C('ИП Смирнов', 'Алексей Смирнов', '+7-999-444-55-66', 'smirnov@mail.ru', null);

  // ─── Грузы ───
  const G = (name, description, weightPerUnit, volumePerUnit) =>
    push('cargo', { name, description, weightPerUnit, volumePerUnit });

  const g1 = G('Строительные материалы', 'Кирпич, цемент, песок', 50.0, 0.1);
  const g2 = G('Электроника', 'Смартфоны, ноутбуки', 0.5, 0.01);
  const g3 = G('Мебель', 'Столы, стулья, шкафы', 25.0, 0.5);

  // ─── Транспорт ───
  const V = (plateNumber, driverName, capacity, status, license) =>
    push('vehicles', {
      plateNumber,
      driverName,
      capacity,
      status,
      driverLicense: license || null,
    });

  const v1 = V('А123ВС 777', 'Иванов Иван Иванович', 2000.0, 'active', {
    id: 1,
    number: 'DL-001',
    issuedAt: '2020-01-15T00:00:00Z',
    expiresAt: '2025-01-15T00:00:00Z',
  });
  const v2 = V('В456УЕ 777', 'Петров Петр Петрович', 1500.0, 'active', {
    id: 2,
    number: 'DL-002',
    issuedAt: '2021-03-10T00:00:00Z',
    expiresAt: '2026-03-10T00:00:00Z',
  });
  const v3 = V('С789ОК 777', 'Сидоров Сидор Сидорович', 3000.0, 'maintenance', {
    id: 3,
    number: 'DL-003',
    issuedAt: '2019-06-20T00:00:00Z',
    expiresAt: '2024-06-20T00:00:00Z',
  });

  // ─── Маршруты ───
  const R = (name, origin, destination, distance, vehicleId, estimatedTime, status) =>
    push('routes', { name, origin, destination, distance, vehicleId, estimatedTime, status });

  const r1 = R('Москва-Санкт-Петербург', 'Москва', 'Санкт-Петербург', 700.0, v1, 8.0, 'active');
  const r2 = R('Москва-Казань', 'Москва', 'Казань', 800.0, v2, 10.0, 'active');
  const r3 = R('Санкт-Петербург-Казань', 'Санкт-Петербург', 'Казань', 1200.0, v1, 15.0, 'completed');

  // ─── Заказы ───
  const O = (orderNumber, clientId, cargoIds, routeIds, cargoDescription, weight, volume, shippingDate, status, deliveryDate = null) =>
    push('orders', {
      orderNumber,
      clientId,
      cargoIds,
      routeIds,
      cargoDescription,
      weight,
      volume,
      shippingDate,
      deliveryDate,
      status,
    });

  O('ORD-001', c1, [g1], [r1], 'Строительные материалы', 1500.0, 12.5, '2026-09-01T00:00:00Z', 'delivered', '2026-09-05T00:00:00Z');
  O('ORD-002', c1, [g2], [r2], 'Электроника', 350.0, 3.2, '2026-09-03T00:00:00Z', 'in_transit');
  O('ORD-003', c2, [g3], [r1], 'Мебель', 800.0, 8.0, '2026-08-28T00:00:00Z', 'delivered', '2026-08-30T00:00:00Z');
  O('ORD-004', c3, [g1, g2], [r3], 'Продукты питания', 2000.0, 15.0, '2026-09-01T00:00:00Z', 'in_transit');
  O('ORD-005', c3, [g3], [r2], 'Запасные части', 120.0, 1.5, '2026-08-25T00:00:00Z', 'cancelled');

  // ─── Пользователи ───
  push('users', { username: 'admin', passwordHash: hash('admin123'), fullName: 'Администратор', email: 'admin@logist.local', role: 'admin' });
  push('users', { username: 'librarian', passwordHash: hash('librarian123'), fullName: 'Петрова А. С.', email: 'petrova@logist.local', role: 'librarian' });
  push('users', { username: 'reader', passwordHash: hash('reader123'), fullName: 'Смирнов П. А.', email: 'smirnov@example.com', role: 'reader' });
}

function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({ id, ...obj, createdAt: new Date().toISOString(), deletedAt: null });
  return id;
}

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

// ──────────────────────── развёртывание объектов ────────────────────────

function slimClient(id) {
  const c = db.clients.find((x) => x.id === id);
  return c ? { id: c.id, companyName: c.companyName } : null;
}

function expandOrder(o) {
  return {
    id: o.id,
    orderNumber: o.orderNumber,
    client: slimClient(o.clientId),
    clientId: o.clientId,
    cargo: o.cargoIds
      .map((id) => db.cargo.find((g) => g.id === id))
      .filter(Boolean)
      .map((g) => ({ id: g.id, name: g.name })),
    cargoIds: o.cargoIds,
    routes: o.routeIds
      .map((id) => db.routes.find((r) => r.id === id))
      .filter(Boolean)
      .map((r) => ({ id: r.id, name: r.name })),
    routeIds: o.routeIds,
    cargoDescription: o.cargoDescription,
    weight: o.weight,
    volume: o.volume,
    shippingDate: o.shippingDate,
    deliveryDate: o.deliveryDate,
    status: o.status,
    createdAt: o.createdAt,
    deletedAt: o.deletedAt,
  };
}

function expandRoute(r) {
  const v = db.vehicles.find((x) => x.id === r.vehicleId);
  return {
    id: r.id,
    name: r.name,
    origin: r.origin,
    destination: r.destination,
    distance: r.distance,
    vehicle: v ? { id: v.id, plateNumber: v.plateNumber } : null,
    vehicleId: r.vehicleId,
    estimatedTime: r.estimatedTime,
    status: r.status,
    createdAt: r.createdAt,
    deletedAt: r.deletedAt,
  };
}

function expandVehicle(v) {
  return {
    id: v.id,
    plateNumber: v.plateNumber,
    driverName: v.driverName,
    capacity: v.capacity,
    status: v.status,
    driverLicense: v.driverLicense,
    createdAt: v.createdAt,
    deletedAt: v.deletedAt,
  };
}

function expandUser(u) {
  return {
    id: u.id,
    username: u.username,
    fullName: u.fullName,
    email: u.email,
    role: u.role,
  };
}

const EXPANDERS = {
  clients: (c) => c,
  orders: expandOrder,
  cargo: (g) => g,
  routes: expandRoute,
  vehicles: expandVehicle,
};

// ─────────────────────────── общие операции ───────────────────────────

function searchableText(collection, item) {
  switch (collection) {
    case 'clients': return [item.companyName, item.contactPerson, item.email].join(' ');
    case 'orders': return [item.orderNumber, item.cargoDescription].join(' ');
    case 'cargo': return [item.name, item.description].join(' ');
    case 'routes': return [item.name, item.origin, item.destination].join(' ');
    case 'vehicles': return [item.plateNumber, item.driverName].join(' ');
    default: return '';
  }
}

function applyFilters(collection, rows, q) {
  let result = rows;

  if (q.search) {
    const needle = String(q.search).toLowerCase();
    result = result.filter((x) => searchableText(collection, x).toLowerCase().includes(needle));
  }

  if (collection === 'orders') {
    if (q.clientId) result = result.filter((o) => o.clientId === Number(q.clientId));
    if (q.status) result = result.filter((o) => o.status === q.status);
    if (q.cargoId) result = result.filter((o) => o.cargoIds.includes(Number(q.cargoId)));
    if (q.routeId) result = result.filter((o) => o.routeIds.includes(Number(q.routeId)));
    if (q.dateFrom) result = result.filter((o) => new Date(o.shippingDate) >= new Date(q.dateFrom));
    if (q.dateTo) result = result.filter((o) => new Date(o.shippingDate) <= new Date(q.dateTo));
  }

  if (collection === 'routes') {
    if (q.vehicleId) result = result.filter((r) => r.vehicleId === Number(q.vehicleId));
    if (q.status) result = result.filter((r) => r.status === q.status);
  }

  if (collection === 'vehicles') {
    if (q.status) result = result.filter((v) => v.status === q.status);
  }

  return result;
}

function applySort(rows, sort) {
  if (!sort) return rows;
  const [field, dirRaw] = String(sort).split(',');
  const dir = (dirRaw || 'asc').toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const av = a[field];
    const bv = b[field];
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
    return String(av).localeCompare(String(bv), 'ru') * dir;
  });
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  const totalPages = Math.max(1, Math.ceil(total / size));
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages,
  };
}

// ─────────────────────────────── валидация ───────────────────────────────

function validate(collection, body, id = null) {
  const e = {};
  const str = (v) => (typeof v === 'string' ? v.trim() : '');

  if (collection === 'clients') {
    if (!str(body.companyName)) e.companyName = 'Укажите название компании';
    else if (str(body.companyName).length > 200) e.companyName = 'Не длиннее 200 символов';
    else {
      const dup = db.clients.find((c) => c.companyName === str(body.companyName) && c.id !== id && !c.deletedAt);
      if (dup) e.companyName = 'Компания с таким названием уже существует';
    }

    if (!str(body.contactPerson)) e.contactPerson = 'Укажите контактное лицо';

    if (!str(body.phone)) e.phone = 'Укажите телефон';

    if (!str(body.email)) e.email = 'Укажите email';
    else if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(str(body.email))) e.email = 'Некорректный адрес почты';
    else {
      const dup = db.clients.find((c) => c.email === str(body.email) && c.id !== id && !c.deletedAt);
      if (dup) e.email = 'Клиент с таким email уже существует';
    }
  }

  if (collection === 'orders') {
    if (!str(body.orderNumber)) e.orderNumber = 'Укажите номер заказа';
    else {
      const dup = db.orders.find((o) => o.orderNumber === str(body.orderNumber) && o.id !== id && !o.deletedAt);
      if (dup) e.orderNumber = 'Заказ с таким номером уже существует';
    }

    if (!body.clientId) e.clientId = 'Выберите клиента';
    else if (!db.clients.find((c) => c.id === Number(body.clientId) && !c.deletedAt)) {
      e.clientId = 'Клиент не найден';
    }

    if (!Array.isArray(body.cargoIds) || !body.cargoIds.length) e.cargoIds = 'Выберите хотя бы один груз';
    if (!Array.isArray(body.routeIds) || !body.routeIds.length) e.routeIds = 'Выберите хотя бы один маршрут';

    if (!str(body.cargoDescription)) e.cargoDescription = 'Укажите описание груза';

    const weight = Number(body.weight);
    if (!weight || weight <= 0) e.weight = 'Вес должен быть положительным';

    const volume = Number(body.volume);
    if (!volume || volume <= 0) e.volume = 'Объём должен быть положительным';

    if (!str(body.shippingDate)) e.shippingDate = 'Укажите дату отправки';
  }

  if (collection === 'cargo') {
    if (!str(body.name)) e.name = 'Укажите название груза';
    else {
      const dup = db.cargo.find((c) => c.name.toLowerCase() === str(body.name).toLowerCase() && c.id !== id && !c.deletedAt);
      if (dup) e.name = 'Груз с таким названием уже существует';
    }

    const w = Number(body.weightPerUnit);
    if (!w || w <= 0) e.weightPerUnit = 'Вес должен быть положительным';

    const v = Number(body.volumePerUnit);
    if (!v || v <= 0) e.volumePerUnit = 'Объём должен быть положительным';
  }

  if (collection === 'routes') {
    if (!str(body.name)) e.name = 'Укажите название маршрута';
    else {
      const dup = db.routes.find((r) => r.name.toLowerCase() === str(body.name).toLowerCase() && r.id !== id && !r.deletedAt);
      if (dup) e.name = 'Маршрут с таким названием уже существует';
    }

    if (!str(body.origin)) e.origin = 'Укажите точку отправления';
    if (!str(body.destination)) e.destination = 'Укажите точку назначения';

    const d = Number(body.distance);
    if (!d || d <= 0) e.distance = 'Расстояние должно быть положительным';

    if (!body.vehicleId) e.vehicleId = 'Выберите транспорт';
    else if (!db.vehicles.find((v) => v.id === Number(body.vehicleId) && !v.deletedAt)) {
      e.vehicleId = 'Транспорт не найден';
    }

    const t = Number(body.estimatedTime);
    if (!t || t <= 0) e.estimatedTime = 'Время должно быть положительным';
  }

  if (collection === 'vehicles') {
    if (!str(body.plateNumber)) e.plateNumber = 'Укажите номер машины';
    else {
      const dup = db.vehicles.find((v) => v.plateNumber === str(body.plateNumber) && v.id !== id && !v.deletedAt);
      if (dup) e.plateNumber = 'Машина с таким номером уже существует';
    }

    if (!str(body.driverName)) e.driverName = 'Укажите водителя';

    const c = Number(body.capacity);
    if (!c || c <= 0) e.capacity = 'Грузоподъёмность должна быть положительной';
  }

  return e;
}

// ──────────────────────────── HTTP-обвязка ────────────────────────────

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function currentUser(req) {
  const header = req.headers['authorization'] || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.users.find((u) => u.id === payload.sub && !u.deletedAt) || null;
}

const ROLE_LEVEL = { reader: 1, librarian: 2, admin: 3 };

function requireRole(res, user, minRole) {
  if (!user) {
    fail(res, 401, 'Требуется аутентификация');
    return false;
  }
  if (ROLE_LEVEL[user.role] < ROLE_LEVEL[minRole]) {
    fail(res, 403, `Операция доступна начиная с роли «${minRole}»`);
    return false;
  }
  return true;
}

const COLLECTIONS = ['clients', 'orders', 'cargo', 'routes', 'vehicles'];

// ─────────────────────────────── маршруты ───────────────────────────────

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();
  const user = currentUser(req);

  // Учебные переключатели
  if (q.__fail) {
    return fail(res, Number(q.__fail), 'Ошибка вызвана намеренно параметром __fail');
  }

  // ── служебные ──
  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  // ── аутентификация ──
  if (path === '/api/auth/register' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const errors = {};
    const username = String(body.username || '').trim();
    const password = String(body.password || '');
    if (username.length < 3) errors.username = 'Логин не короче трёх символов';
    else if (db.users.find((u) => u.username === username)) errors.username = 'Такой логин уже занят';
    if (password.length < 8) errors.password = 'Пароль не короче восьми символов';
    else if (!/\d/.test(password)) errors.password = 'Пароль должен содержать цифру';
    if (body.email && !/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(String(body.email)))
      errors.email = 'Некорректный адрес почты';

    if (Object.keys(errors).length) {
      return send(res, 422, { message: 'Ошибка валидации', errors });
    }

    const id = push('users', {
      username,
      passwordHash: hash(password),
      fullName: String(body.fullName || username),
      email: String(body.email || ''),
      role: 'reader',
    });
    return send(res, 201, expandUser(db.users.find((u) => u.id === id)));
  }

  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const found = db.users.find(
      (u) => u.username === String(body.username || '').trim() && !u.deletedAt
    );
    if (!found || found.passwordHash !== hash(String(body.password || ''))) {
      return fail(res, 401, 'Неверный логин или пароль');
    }

    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);

    return send(res, 200, {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TTL,
      user: expandUser(found),
    });
  }

  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    const found = db.users.find((u) => u.id === payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');

    db.refreshTokens.delete(token);
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);

    return send(res, 200, { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: expandUser(found) });
  }

  if (path === '/api/auth/me' && method === 'GET') {
    if (!user) return fail(res, 401, 'Требуется аутентификация');
    return send(res, 200, expandUser(user));
  }

  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body && body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }

  // ── управление пользователями (только admin) ──
  if (path === '/api/users' && method === 'GET') {
    if (!requireRole(res, user, 'admin')) return;
    const rows = applySort(db.users.filter((u) => !u.deletedAt), q.sort);
    const page = paginate(rows, q);
    return send(res, 200, { ...page, items: page.items.map(expandUser) });
  }

  // ── единообразный CRUD ──
  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);
  let m = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);

  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    if (!requireRole(res, user, 'librarian')) return;

    const body = await readBody(req);
    const ids = Array.isArray(body && body.ids) ? body.ids.map(Number) : [];
    if (!ids.length) {
      return send(res, 422, { message: 'Ошибка валидации', errors: { ids: 'Передайте непустой список идентификаторов' } });
    }

    let deleted = 0;
    for (const row of db[collection]) {
      if (ids.includes(row.id) && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    }
    return send(res, 200, { deleted });
  }

  if (m) {
    const collection = m[1];
    const id = m[2] ? Number(m[2]) : null;
    const action = m[3] || null;

    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    const expand = EXPANDERS[collection];

    // восстановление
    if (action === 'restore' && method === 'POST') {
      if (!requireRole(res, user, 'admin')) return;
      const row = db[collection].find((x) => x.id === id);
      if (!row) return fail(res, 404, 'Объект не найден');
      row.deletedAt = null;
      return send(res, 200, expand(row));
    }

    // список
    if (id === null && method === 'GET') {
      let rows = db[collection];
      if (q.includeDeleted !== 'true') rows = rows.filter((x) => !x.deletedAt);

      rows = applyFilters(collection, rows, q);
      rows = applySort(rows, q.sort);
      const page = paginate(rows, q);
      return send(res, 200, { ...page, items: page.items.map(expand) });
    }

    // одна запись
    if (id !== null && method === 'GET') {
      const row = db[collection].find((x) => x.id === id && (q.includeDeleted === 'true' || !x.deletedAt));
      if (!row) return fail(res, 404, 'Объект не найден');
      return send(res, 200, expand(row));
    }

    // создание
    if (id === null && method === 'POST') {
      if (!requireRole(res, user, 'librarian')) return;
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const errors = validate(collection, body);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });

      const data = normalize(collection, body);
      const newId = push(collection, data);
      const row = db[collection].find((x) => x.id === newId);
      return send(res, 201, expand(row));
    }

    // изменение
    if (id !== null && (method === 'PUT' || method === 'PATCH')) {
      if (!requireRole(res, user, 'librarian')) return;
      const row = db[collection].find((x) => x.id === id && !x.deletedAt);
      if (!row) return fail(res, 404, 'Объект не найден');

      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const merged = method === 'PATCH' ? { ...row, ...body } : body;
      const errors = validate(collection, merged, id);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });

      Object.assign(row, normalize(collection, merged));
      return send(res, 200, expand(row));
    }

    // удаление
    if (id !== null && method === 'DELETE') {
      const hard = q.hard === 'true';
      if (!requireRole(res, user, hard ? 'admin' : 'librarian')) return;

      const index = db[collection].findIndex((x) => x.id === id);
      if (index === -1) return fail(res, 404, 'Объект не найден');

      if (hard) {
        // Проверка связей при физическом удалении
        if (collection === 'clients') {
          const linked = db.orders.some((o) => o.clientId === id && !o.deletedAt);
          if (linked) return fail(res, 409, 'На клиента ссылаются заказы');
        }
        if (collection === 'cargo') {
          const linked = db.orders.some((o) => o.cargoIds.includes(id) && !o.deletedAt);
          if (linked) return fail(res, 409, 'Груз используется в заказах');
        }
        if (collection === 'routes') {
          const linked = db.orders.some((o) => o.routeIds.includes(id) && !o.deletedAt);
          if (linked) return fail(res, 409, 'Маршрут используется в заказах');
        }
        if (collection === 'vehicles') {
          const linked = db.routes.some((r) => r.vehicleId === id && !r.deletedAt);
          if (linked) return fail(res, 409, 'Транспорт используется в маршрутах');
        }
        db[collection].splice(index, 1);
      } else {
        db[collection][index].deletedAt = new Date().toISOString();
      }
      return send(res, 204);
    }
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

function normalize(collection, body) {
  const num = (v) => (v == null || v === '' ? null : Number(v));
  const str = (v) => (v == null ? '' : String(v).trim());
  const ids = (v) => (Array.isArray(v) ? v.map(Number).filter((n) => Number.isInteger(n)) : []);

  switch (collection) {
    case 'clients':
      return {
        companyName: str(body.companyName),
        contactPerson: str(body.contactPerson),
        phone: str(body.phone),
        email: str(body.email),
        address: str(body.address) || null,
      };
    case 'orders':
      return {
        orderNumber: str(body.orderNumber),
        clientId: num(body.clientId),
        cargoIds: ids(body.cargoIds),
        routeIds: ids(body.routeIds),
        cargoDescription: str(body.cargoDescription),
        weight: num(body.weight) ?? 0,
        volume: num(body.volume) ?? 0,
        shippingDate: str(body.shippingDate),
        deliveryDate: body.deliveryDate || null,
        status: str(body.status) || 'in_transit',
      };
    case 'cargo':
      return {
        name: str(body.name),
        description: str(body.description),
        weightPerUnit: num(body.weightPerUnit) ?? 0,
        volumePerUnit: num(body.volumePerUnit) ?? 0,
      };
    case 'routes':
      return {
        name: str(body.name),
        origin: str(body.origin),
        destination: str(body.destination),
        distance: num(body.distance) ?? 0,
        vehicleId: num(body.vehicleId),
        estimatedTime: num(body.estimatedTime) ?? 0,
        status: str(body.status) || 'active',
      };
    case 'vehicles':
      return {
        plateNumber: str(body.plateNumber),
        driverName: str(body.driverName),
        capacity: num(body.capacity) ?? 0,
        status: str(body.status) || 'active',
        driverLicense: body.driverLicense || null,
      };
    default:
      return { ...body };
  }
}

// ─────────────────────────────── запуск ───────────────────────────────

seed();

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }

  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((r) => setTimeout(r, Math.min(delay, 10000)));

  const started = Date.now();
  try {
    await handle(req, res, url);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) fail(res, 500, 'Внутренняя ошибка сервера: ' + err.message);
  }
  console.log(
    `${req.method.padEnd(6)} ${url.pathname}${url.search}  → ${res.statusCode}  ${Date.now() - started} мс`
  );
});

server.listen(PORT, () => {
  console.log('');
  console.log('  Учебное API «Логистика»');
  console.log(`  Адрес:              http://localhost:${PORT}/api`);
  console.log(`  Разрешённый источник: ${ORIGIN}`);
  console.log(`  Срок жизни токена:  ${ACCESS_TTL} с`);
  console.log('');
  console.log('  Учётные записи:  admin/admin123   librarian/librarian123   reader/reader123');
  console.log('  Сброс данных:    POST /api/__reset');
  console.log('  Задержка ответа: любой запрос с ?__delay=1500');
  console.log('  Ошибка по требованию: любой запрос с ?__fail=500');
  console.log('');
});
