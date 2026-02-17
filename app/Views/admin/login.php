<!doctype html>
<html lang="pl">
<head>
  <meta charset="utf-8">
  <title>Admin Login</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body{font-family:system-ui;margin:40px;max-width:420px}
    input{width:100%;padding:10px;margin:8px 0}
    button{padding:10px 14px}
    .err{color:#b00020;margin:10px 0}
  </style>
</head>
<body>
  <h2>Panel admina – logowanie</h2>
  <?php if (!empty($error)): ?><div class="err"><?= esc($error) ?></div><?php endif; ?>

  <form method="post" action="/admin/login">
    <input type="email" name="email" placeholder="Email" required>
    <input type="password" name="password" placeholder="Hasło" required>
    <button type="submit">Zaloguj</button>
  </form>
</body>
</html>
