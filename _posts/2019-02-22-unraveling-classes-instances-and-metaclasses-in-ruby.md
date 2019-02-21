---
layout: post
title: "Hiểu kỹ hơn về Classes, Instances và Metaclasses trong Ruby"
date: 2019-02-22
---

> Bài viết này dịch từ bài gốc - [Unraveling Classes, Instances and Metaclasses in Ruby](https://blog.appsignal.com/2019/02/05/ruby-magic-classes-instances-and-metaclasses.html)

Trong bài viết này sẽ học về class và các instance method làm việc thế nào trong Ruby. Với đó sẽ tìm hiểu sự khác biệt giữa định nghĩa một method bằng cách truyền cụ thể "definee" và sử dụng `class << self` hoặc `instance_eval`.

### Class Instances và Instance Methods
Để hiểu tại sao metaclass sử dụng trong Ruby, hãy thử sự khác biệt giữa instance và class methods.

Trong Ruby một *class* là một object định nghĩa thiết kế để tạo các object khác. Các class định nghĩa các method là sẵn có trong bất cứ instance của class đó.

Định nghĩa một method trong một class tạo một *instance method* với class đó. Instance tiếp theo của class đó sẽ có method sẵn có.

```
class User
  def initialize(name)
    @name = name
  end

  def name
    @name
  end
end

user = User.new('Thijs')
user.name # => "Thijs"
```

Trong ví dụ trên tạo một class tên `User` với một *instance method* tên là `#name` trả về tên của user. Sử dụng class tạo một *class instance* và lưu nó trong một biến tên `user`. Do `user` làm một instance của class `User` nó có method `#name` sẵn.

Một class chứa các instance method của nó trong [method table](https://en.wikipedia.org/wiki/Virtual_method_table). Bất kỹ instance của class nó trỏ tới class method table của nó để truy cập tới các instance method của nó.

### Class Objects
Một *class method* là một method có thể gọi trực tiếp với một class mà không phải khởi tạo instance trước. Một class method tạo bởi tiền tố `self.` khi định nghĩa nó.

Một class là chính nó một object. Một constant trỏ với class object vậy các class method được định nghĩa trên nó có thể gọi bất cứ chỗ nào trong ứng dụng.

```
class User
  # ...

  def self.all
    [new("Thijs"), new("Robert"), new("Tom")]
  end
end

User.all
=> [#<User:0x007fbe9c870318 @name="Thijs">, #<User:0x007fbe9c8702c8 @name="Robert">, #<User:0x007fbe9c870200 @name="Tom">]
```

Các method định nghĩa với tiền tố `self.` không được thêm vào method table của class. Thay vì đó, nó được thêm vào metaclass của class.

### Metaclasses

Ngoài một class, một object trong Ruby có một metaclass ẩn. Các Metaclass là singletons, có nghĩa chúng thuộc về một object đơn. Nếu tạo nhiều instance của một class chúng sẽ chia sẻ class giống nhau, nhưng chúng có metaclasses riêng biệt.

```
thijs, robert, tom = User.all

thijs.class # => User
robert.class # => User
tom.class # => User

thijs.singleton_class => #<Class:#<User:0x007fbe9d007a68>>
robert.singleton_class => #<Class:#<User:0x007fbe9d0079c8>>
tom.singleton_class => #<Class:#<User:0x007fbe9d007900>>
```
Trong ví dụ này, thấy rằng tùy một object có class `User` nhưng singleton_class có IDs khác nhau nghĩa là chúng là object tách biệt.

Được truy cập tới một metaclass, Ruby cho phép thêm các method trực tiếp tới các object có sẵn. Cách này sẽ không thêm method tới class của object.

```
robert = User.new("Robert")

def robert.last_name
  "Beekman"
end

robert.last_name # => "Beekman"
User.new("Tom").last_name => NoMethodError: undefined method `last_name' for #<User:0x007fbe9ca75a78 @name="Tom">
```

Trong ví dụ này, chúng ta thêm `#last_name` cho user lưu trong biến `robert`. Tuy nhiên, `robert` là một instance của `User`, các biến instance mới của `User` không thể truy cập tới method `#last_name` mà nó chỉ có với metaclass của `robert`.

### `self` là gì?

Khi định nghĩa một method và truyền đối số, method mới được thêm vào metaclass của đối số thay vì them nó vào method table của class.

```
tom = User.new("Tom")

def tom.last_name
  "de Bruijn"
end
```

Chúng ta thêm `#last_name` trực tiếp trên object `tom` bằng truyền `tom` đối số khi định nghĩa method.

Ở đây giống như cách làm việc của các class method.

```
class User
  # ...

  def self.all
    [new("Thijs"), new("Robert"), new("Tom")]
  end
end
```

Ở đây chúng ta truyền cụ thể `self` là đối số khi tạo `.all` method. Trong định nghĩa một class `self` trỏ với class(`User` trong ví dụ này) vậy method `.all` thêm vào metaclass của `User`.

Vì `User` là một object lưu trong một constant, chúng ta có thể truy cập cùng một object và metaclass mỗi khi chúng ta tham chiếu nó.

### Bên trong Metaclass

Chúng ta đã biết rằng các class method là các method trong metaclass của class object. Bằng biết điều này chúng ta sẽ xem xét một số mẹo tạo các class method mà bạn có thể từng gặp.

`class << self`

Một số thư viện sử dụng `class << self` để định nghĩa các class method. Cú pháp này mở metaclass của class hiện tại và tương tác trực tiếp.

```
class User
  class << self
    self # => #<Class:User>

    def all
      [new("Thijs"), new("Robert"), new("Tom")]
    end
  end
end

User.all # => [#<User:0x00007fb01701efb8 @name="Thijs">, #<User:0x00007fb01701ef68 @name="Robert">, #<User:0x00007fb01701ef18 @name="Tom">]

```

Trong ví dụ này tạo một class method có tên `User.all` bằng thêm một method cho metaclass của `User`. Thay vì truyền đối số cụ thể cho method như trước chúng ta set `self` cho metaclass của `User` thay vì `User`.

Như đã tìm hiểu qua bất kfy định nghĩa method không truyền đối số cụ thể được thêm là một instance method của class đó. Trong block, class hiện tại là metaclass của `User`(`#<Class:User>`).

`instance_eval`

Có cách khác là dùng `instance_eval` làm như nhau với một khác biệt lớn. Mặc dù metaclass của class nhận các method được định nhgĩa trong block `self` vẫn tham chiếu tới main class.

```
class User
  instance_eval do
    self # => User

    def all
      [new("Thijs"), new("Robert"), new("Tom")]
    end
  end
end

User.all # => [#<User:0x00007fb01701efb8 @name="Thijs">, #<User:0x00007fb01701ef68 @name="Robert">, #<User:0x00007fb01701ef18 @name="Tom">]
```

Trong ví dụ này chúng ta định nghĩa một instance method trên metaclass của `User` giống trước nhưng `self` vẫn trỏ tới `User`. Tùy nó thường trỏ với object giống nhau, "default definee" và `self` có thể trỏ tới các object khác nhau.

### Kết luận
Hy vọng bài này giống hiểu rõ hơn về các class, instance và metaclass trong ruby.

##### Tham khảo
- [Unraveling Classes, Instances and Metaclasses in Ruby](https://blog.appsignal.com/2019/02/05/ruby-magic-classes-instances-and-metaclasses.html)
