<!doctype html>
<html lang="pl">
<head>
  <meta charset="utf-8">
  <title>Typy wydarzeń</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body{font-family:system-ui;margin:40px;max-width:800px}
    table{border-collapse:collapse;width:100%}
    td,th{border:1px solid #ddd;padding:8px}
    .swatch{display:inline-block;width:18px;height:18px;border-radius:4px;border:1px solid #ccc;vertical-align:middle}
    .err{color:#b00020;margin:10px 0}
  </style>
</head>
<body>
  <h2>Globalne typy wydarzeń</h2>
  <p><a href="/admin">← Dashboard</a></p>

  <?php if (!empty($error)): ?><div class="err"><?= esc($error) ?></div><?php endif; ?>

  <h3>Dodaj typ</h3>
  <form method="post" action="/admin/types/create">
    <input name="name" placeholder="Nazwa" required>
    <input name="color_hex" placeholder="#RRGGBB" value="#007AFF" required>
    <button type="submit">Dodaj</button>
  </form>

  <h3>Lista</h3>
  <table>
    <thead>
      <tr><th>ID</th><th>Nazwa</th><th>Kolor</th></tr>
    </thead>
    <tbody>
      <?php foreach ($types as $t): ?>
        <tr>
          <td><?= (int)$t['id'] ?></td>
          <td><?= esc($t['name']) ?></td>
          <td>
            <span class="swatch" style="background:<?= esc($t['color_hex']) ?>"></span>
            <?= esc($t['color_hex']) ?>
          </td>
        </tr>
      <?php endforeach; ?>
    </tbody>
  </table>
</body>
</html>
