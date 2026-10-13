// Port of `Bap_cache_gc`: the garbage collector of the cache.
//
// The collector removes randomly selected entries, prioritizing the larger
// ones, until the cache fits the lower bound of the configuration. An
// entry is selected with a probability proportional to its size (but not
// less than `min_entry_size`): a uniformly distributed number `u` in
// `[0, T)`, where `T` is the total size, selects the entry `k` such that
// `F(k-1) <= u < F(k)`, where `F` is the cumulative distribution of the
// sizes. Selection repeats until the selected distinct entries are large
// enough; they are then shuffled and removed.

///|
/// A cache entry considered by the collector.
pub(all) struct Entry {
  path : String
  /// the size of the entry, in kilobytes
  size : Int32
} derive(Eq, Debug)

///|
pub extend Entry with Eq::{equal, not_equal}

///|
pub extend Entry with Debug::{to_repr}

///|
/// The smallest size (in kilobytes) that an entry has in the distribution.
pub let min_entry_size : Int32 = 4

///|
/// The entries of the data folder `dir` (upstream `read_cache`).
pub fn read_entries(dir : String) -> Array[Entry] {
  let names = @native_io.read_dir(dir).unwrap_or([])
  let entries = []
  for name in names {
    let path = concat(dir, name)
    match @native_io.stat(path) {
      Ok(st) => entries.push({ path, size: (st.size / 1024L).to_int(), })
      Err(_) => ()
    }
  }
  entries
}

///|
/// The total size of the entries, in kilobytes.
pub fn total_size(entries : ArrayView[Entry]) -> Int32 {
  entries.fold(init=0, (s, e) => s + e.size)
}

///|
/// The starts of the intervals of the cumulative distribution: the `i`-th
/// entry owns `[starts[i], starts[i + 1])` (upstream `cdf`).
fn cdf(sizes : ArrayView[Int32]) -> Array[Int32] {
  let starts = []
  let mut prev = 0
  for size in sizes {
    starts.push(prev)
    prev += if size > min_entry_size { size } else { min_entry_size }
  }
  starts
}

///|
/// The index of the interval that contains `u` (upstream `closest_key`
/// with `Less_or_equal_to`).
fn find_interval(starts : Array[Int32], u : Int32) -> Int32 {
  let mut lo = 0
  let mut hi = starts.length() - 1
  while lo < hi {
    let mid = lo + (hi - lo + 1) / 2
    if starts[mid] <= u {
      lo = mid
    } else {
      hi = mid - 1
    }
  }
  lo
}

///|
/// Selects the indexes of the entries to remove (upstream `select`):
/// distinct entries are drawn with `random(total)` (a uniformly
/// distributed number in `[0, total)`) until their sizes sum up to at
/// least `to_free` kilobytes. `total` is the total size of the entries.
///
/// Entries whose interval starts after `total` (possible when many
/// entries are smaller than `min_entry_size`) cannot be drawn; if random
/// draws stop making progress, the remaining entries are taken largest
/// first, which also guarantees termination.
pub fn select(
  sizes : ArrayView[Int32],
  total~ : Int32,
  to_free~ : Int32,
  random : (Int32) -> Int32,
) -> Array[Int32] {
  let n = sizes.length()
  if n == 0 || total <= 0 {
    return []
  }
  let starts = cdf(sizes)
  let selected : Map[Int32, Unit] = Map([])
  let order = []
  let mut freed = 0
  let mut misses = 0
  let max_misses = 64 * n + 1024
  while freed < to_free && order.length() < n && misses < max_misses {
    let i = find_interval(starts, random(total))
    if selected.contains(i) {
      misses += 1
    } else {
      selected[i] = ()
      order.push(i)
      freed += sizes[i]
    }
  }
  if freed < to_free && order.length() < n {
    let rest = Array::makei(n, i => i).filter(i => !selected.contains(i))
    rest.sort_by((a, b) => sizes[b].compare(sizes[a]))
    for i in rest {
      if freed >= to_free {
        break
      }
      order.push(i)
      freed += sizes[i]
    }
  }
  order
}

///|
fn new_rng() -> @random.Rand {
  let seed = match @env.rand(32) {
    Some(bytes) => bytes
    None => {
      let now = @env.now()
      Bytes::makei(32, i => (now >> (8 * (i % 8))).to_byte())
    }
  }
  @random.Rand::chacha8(seed~)
}

///|
fn remove_entry(e : Entry) -> Bool {
  match @native_io.remove_file(e.path) {
    Ok(_) => true
    Err(err) => {
      warning("unable to remove entry: \{err}")
      false
    }
  }
}

///|
/// Runs `f` unless another process is collecting the cache at `root`.
fn with_gc_lock(root : String, f : () -> Int32) -> Int32 {
  match @native_io.lock_file(concat(root, "gc.lock"), blocking=false) {
    Ok(lock) => {
      defer lock.unlock() |> ignore
      f()
    }
    Err(_) => 0
  }
}

///|
/// Shrinks the cache at `root` to the lower bound of `cfg` if its size
/// exceeds the lower bound or, if `by_threshold`, the GC threshold
/// (upstream `shrink`). Returns the number of removed entries. Does
/// nothing if another process is already collecting the cache.
pub fn shrink(
  cfg : Config,
  by_threshold~ : Bool = false,
  root~ : String = root(),
) -> Int32 {
  with_gc_lock(root, () => {
    let entries = read_entries(data_dir(root~))
    let total = total_size(entries)
    let lower_bound = cfg.lower_bound()
    let max_size = if by_threshold {
      cfg.gc_threshold() * 1024
    } else {
      lower_bound
    }
    if total <= max_size {
      return 0
    }
    let rng = new_rng()
    let selected = select(
      entries.map(e => e.size),
      total~,
      to_free=total - lower_bound,
      limit => rng.int(limit~),
    )
    rng.shuffle(selected.length(), (i, j) => {
      let t = selected[i]
      selected[i] = selected[j]
      selected[j] = t
    })
    selected.fold(init=0, (n, i) => {
      if remove_entry(entries[i]) {
        n + 1
      } else {
        n
      }
    })
  })
}

///|
/// Removes all entries of the cache at `root` (upstream `clean`).
/// Returns the number of removed entries.
pub fn clean(root~ : String = root()) -> Int32 {
  read_entries(data_dir(root~)).fold(init=0, (n, e) => {
    if remove_entry(e) {
      n + 1
    } else {
      n
    }
  })
}
