f1 = 0  # count to 3000
f2 = 0  # count to 4000
f3 = 0  # count to 4000
p1 = 2998
p2 = 4000
counter = 0


while True:
    counter = counter + 1

    if f1 == p1 and f2 == p2:
        print(counter)
        break

    if f1 == p1:
        f1 = 0
    else:
        f1 = f1 + 1

    if f2 == p2:
        f2 = 0
    else:
        f2 = f2 + 1

