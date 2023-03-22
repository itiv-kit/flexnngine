import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import plotly.express as px

#read test/image_size_17_kernel_size_5_c_20/_eval_status.txt file and sum up the occurences of each number
f = open('test/image_size_17_kernel_size_5_c_20/_eval_status.txt', 'r')
f1 = f.readlines()
f2 = []


for x in f1:
    #split the line and extract all integers
    for i in x.split():
        if i.isdigit():
            f2.append(int(i))


#print(f2.shape)

f3 = np.array(f2)
print(f3.shape)
f4 = np.bincount(f3)
print(f4.shape)
print("f4: ", f4)
f5 = np.nonzero(f4)[0]
print(f5.shape)
f6 = np.vstack((f5, f4[f5])).T
print(f6.shape)
df = pd.DataFrame(f6, columns = ['Event', 'Occurence'])
print(df)

# create empty major columns for the dataframe
df.insert(0, "Major Major", " ")
df.insert(1, "Major", " ")

#change major colum to "output" for all rows with event number 10, 11 and 12
for eventid in [10, 11, 12]:
    df.loc[df['Event'] == eventid, 'Major'] = 'output'
    df.loc[df['Event'] == eventid, 'Major Major'] = 'state'

for eventid in [20, 21, 22]:
    df.loc[df['Event'] == eventid, 'Major'] = 'calculation'
    df.loc[df['Event'] == eventid, 'Major Major'] = 'state'
    
for eventid in [30, 31, 32, 33]:
    df.loc[df['Event'] == eventid, 'Major'] = 'load data'
    df.loc[df['Event'] == eventid, 'Major Major'] = ' '
       


#df['Major'] = np.where(df['Event'] == 10, 'output')
#df['Major'] = np.where(df['Event'] == 11, 'output', 0)
print(df)

# create new dataframe where Major Major = state
df_state = df.loc[df['Major Major'] == 'state']

print(df_state)

"""facecolor = '#eaeaf2'
font_color = '#525252'
hfont = {'fontname':'Calibri'}
size = 0.3
vals = df_state['Occurence']
# Major category values = sum of minor category values
group_sum = df_state.groupby('Major')['Occurence'].sum()

fig, ax = plt.subplots(figsize=(10,6), facecolor=facecolor)

cmap = plt.colormaps["tab20c"]
outer_colors = cmap(np.arange(3)*4)
inner_colors = cmap([1, 2, 5, 6, 9, 10])

ax.pie(group_sum, 
       radius=1, 
       colors=outer_colors,
       labels= group_sum.index,
       textprops={'color':font_color},
       wedgeprops=dict(width=size, edgecolor='w'))

ax.pie(vals, 
       radius=1-size, # size=0.3
       colors=inner_colors,
       labels=df_state['Event'], 
       labeldistance=0.7,
       label
       wedgeprops=dict(width=size, edgecolor='w'))


plt.show()

print(group_sum)"""

fig = px.sunburst(df_state, path=['Major', 'Event'], values='Occurence')
#fig.write_image("sunburst.png")
fig.show()
