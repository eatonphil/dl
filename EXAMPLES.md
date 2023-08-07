# The language for scripting data language

### API Interactions

```jsx
next_page = "github.com/eatonphil/goraft/stars";
for next_page != "" {
	req = @http.get next;
	
	stars_by_date = {};
	
	for star in req.json.stars {
	  stars_by_date.incr star.date
	}
	
	for date, count in stars_by_date {
	  print `${date} ${count}`
	}

  next_page = req.headers["X_NEXT_URL"]
}
```

### FileSystem Interactions

```jsx
fw = @fs.open "mass.csv" mode=.write;
defer fw.close;

for file in @fs.list glob=`${@fs.cwd}/data/*.csv` {
  fw.append file=file
}
```

### Build System

```jsx
fn rebuild_runner {
  sources = @fs.list glob="src/*.c";
  if @fs.cache.miss files=sources key="c-sources" {
    args = sources;
    args.push proc.env.C_FLAGS;
    args.push many=["-o", "bin/runner" + @platform.os == "windows" ? ".exe" : ""];
    @proc.exec proc.env.CC args=args;
  }
}

fn build_css {
  sources = @fs.list glob="src/**/*.css";
  if @fs.cache.miss files=sources key="css-sources" {
    args = sources;
    args.push ["-o", "out/style.css"];
    @proc.exec "scss" args=args;
  }
}

commands = {
  "runner": &rebuild_runner,
  "css": &css,
};
for arg in @proc.args {
  if arg in commands {
    commands[arg].call;
  } else {
    options = commands.keys.join ", ";
    @proc.exit `Unknown command: ${arg}. Expected one of ${options}.`;
  }
}
```

### Benchmarking

```jsx
N = 10;
to_run = [];
for arg in @proc.args {
  if arg == "-n" or arg == "--times" {
    n = @proc.args.next;
    continue
  }

  if arg.startswith "-" {
    continue
  }

  program.push arg; 
}

for i, prog in to_run {
  if i > 0 {
    print "\n\n";
  }

  stats = @math.stats_stream metrics=.min | .max | .stddev | .median;
  for range N {
    name = prog.part " " at=0;
    before = @time.now;
    @proc.exec name args=(prog.slice prog.part from=name.len);
    after = time.now;
    stats.update (after.diff before as=.seconds);
  }

  print `Program: ${prog}`;
  print `  Median: ${stats.median}s, Standard Deviation: ${stats.stddev}s`;
  print `  Min: ${stats.min}s, Max: ${stats.max}s`;
}
```

### Database Interactions

```jsx
conn = @db.conn
  driver=.pg
  username=proc.env.PG_USERNAME
  password=proc.env.PG_PASSWORD
  database=proc.env.PG_DATABASE
rows = conn.query `
SELECT
  category, COUNT(1)
FROM
  customers
GROUP BY
  category
ORDER BY
  category DESC`

for row in rows {
  print `Category: ${row.category.text}, Total: ${row.total.u64}`;
}
```